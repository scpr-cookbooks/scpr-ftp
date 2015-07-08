use_inline_resources

action :create do
  # -- housekeeping -- #

  execute "generate-pureftpd-vusers" do
    action  :nothing
    command "/usr/local/bin/scprftp-generate-vusers.rb"
  end

  cookbook_file "/usr/local/bin/scprftp-generate-vusers.rb" do
    action  :create
    mode    0755
  end

  # -- make sure our vusers.d dir exists -- #

  directory "/etc/pure-ftpd/vusers.d" do
    action  :create
    mode    0755
  end

  # -- should we create the home dir? -- #

  directory new_resource.home_dir do
    action  :create
    owner   "pureftpd"
    mode    0755

    only_if { new_resource.manage_home }
  end

  # -- Write the users.d file -- #

  home_dir = new_resource.home_dir

  if new_resource.chroot
    home_dir = "#{home_dir}/./"
  end

  passwd_line = "#{new_resource.name}:#{new_resource.password}:#{node.scpr_ftp.uid}:#{node.scpr_ftp.gid}::#{home_dir}::::::::::#{new_resource.ip_range}::"

  file "/etc/pure-ftpd/vusers.d/#{new_resource.name}.user" do
    action  :create
    content passwd_line
    notifies :run, "execute[generate-pureftpd-vusers]", :delayed
  end
end

#----------

action :delete do

  execute "generate-pureftpd-vusers" do
    action  :nothing
    command "/usr/local/bin/scprftp-generate-vusers.rb"
  end

  # -- delete the home dir? -- #
  directory new_resource.home_dir do
    action    :delete
    recursive true
    only_if { new_resource.manage_home }
  end

  file "/etc/pure-ftpd/vusers.d/#{new_resource.name}.user" do
    action :delete
    notifies :run, "execute[generate-pureftpd-vusers]", :delayed
  end
end