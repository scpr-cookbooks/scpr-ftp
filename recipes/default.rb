# -- Install pure-ftpd -- #

group "pureftpd" do
  action  :create
  gid     node.scpr_ftp.gid
end

user "pureftpd" do
  action  :create
  home    node.scpr_ftp.home
  uid     node.scpr_ftp.uid
  gid     node.scpr_ftp.gid
end

directory node.scpr_ftp.home do
  action :create
  recursive true
end

package "pure-ftpd"

service "pure-ftpd" do
  action    :nothing
  supports  [:start,:stop,:restart]
end

# -- Configure pure-ftpd -- #

file "/etc/pure-ftpd/conf/PureDB" do
  action    :create
  content   "/etc/pure-ftpd/pureftp.db"
  notifies  :restart, "service[pure-ftpd]"
end

file "/etc/pure-ftpd/conf/PAMAuthentication" do
  action    :create
  content   "no"
  notifies  :restart, "service[pure-ftpd]"
end

link "/etc/pure-ftpd/auth/50PureDB" do
  action    :create
  to        "/etc/pure-ftpd/conf/PureDB"
  notifies  :restart, "service[pure-ftpd]"
end

# -- User Management -- #

# grab our user list from the databag item. should be a hash
users = data_bag_item(node.scpr_ftp.data_bag, node.scpr_ftp.item)["users"]

# do we have a list of existing users we can pull?
existing = {}
if File.exists?("/etc/scpr-ftp.json")
  existing = begin JSON.parse(File.read("/etc/scpr-ftp.json")) rescue {} end
end

passwd = []

# create/update all users in our current users list
users.each do |user,pass|
  # create home directory
  directory "#{node.scpr_ftp.home}/#{user}" do
    action  :create
    owner   "pureftpd"
    mode    0755
  end

  # create our passwd file line
  passwd << "#{user}:#{pass}:#{node.scpr_ftp.uid}:#{node.scpr_ftp.gid}::#{node.scpr_ftp.home}/#{user}/./::::::::::::"
end

# are there any users in our old list that should be deleted?
(users.keys - existing.keys).each do |user|
  # delete the home directory
  directory "#{node.scpr_ftp.home}/#{user}" do
    action :delete
  end
end

execute "update-pureftpd-passdb" do
  action :nothing
  command "pure-pw mkdb /etc/pure-ftpd/pureftp.db -f /etc/pure-ftpd/pureftp.passwd"
end

# write password file
file "/etc/pure-ftpd/pureftp.passwd" do
  action  :create
  content passwd.sort.join("\n")
  notifies :run, "execute[update-pureftpd-passdb]"
end

# write our new list of existing users
File.open("/etc/scpr-ftp.json","w") do |f|
  f.write users.to_json
end
