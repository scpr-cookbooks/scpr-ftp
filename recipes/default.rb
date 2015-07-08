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

file "/etc/pure-ftpd/conf/PassivePortRange" do
  action    :create
  content   "40000 40100"
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

# create/update all users in our current users list
users.each do |user,obj|
  # support the first version of this recipe, which just had user/pass
  if obj.is_a?(String)
    obj = { "password" => obj, "manage_home" => true }
    users[user] = obj
  end

  scpr_ftp_vuser user do
    action      :create
    password    obj["password"]
    home_dir    obj["home_dir"]
    manage_home obj["manage_home"]
    ip_range    obj["ip_range"]
  end
end

# are there any users in our old list that should be deleted?
(existing.keys - users.keys).each do |user|
  obj = existing[user]

  scpr_ftp_vuser user do
    action      :delete
    home_dir    obj["home_dir"]
    manage_home obj["manage_home"]
  end
end

# write our new list of existing users
File.open("/etc/scpr-ftp.json","w") do |f|
  f.write users.to_json
end