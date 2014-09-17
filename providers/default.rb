action :install do
  # Install FTP server
  package "vsftpd"

  # vsftpd installs the config file to /etc/vsftpd.conf by default.
  # This path is hard-coded into the default Upstart script, and I'd
  # rather not have to manage that since otherwise it's fine. So we'll
  # just live with the location of the config file (I'd rather it be in
  # /etc/vsftpd/)
  template "/etc/vsftpd.conf" do
    source "vsftpd/vsftpd.conf.erb"
    notifies :restart, "service[vsftpd]"
  end

  service 'vsftpd' do
    provider Chef::Provider::Service::Upstart
    supports status: true, restart: true, reload: true, start: true, stop: true
    action [:enable, :start]
  end

  directory "/etc/vsftpd" do
    owner "root"
    group "root"
    mode 0755
    action :create
  end

  # Update /etc/shells to include our ftp user login shell
  template "/etc/shells" do
    source "shells.erb"
  end

  # Setup the user list
  # Since we're using the local filesystem for authentication, we want to
  # only allow the users in this file to login to FTP.
  users = search(:users, "groups:#{new_resource.group}")

  users.each do |user|
    # Setup FTP users.
    # Since vsftpd authenticates against the local system, we need to
    # make user accounts on the OS. We prevent them from logging in
    # via SSH by setting their shell to nologin (or similar).
    user user['id'] do
      uid user['uid']
      group user['gid']
      password user['password']
      home user['home']
      supports manage_home: false
      shell node.vsftpd.ftp_user_shell
    end
  end

  ftpgroup = search(:groups, "id:ftp").first

  group ftpgroup['id'] do
    gid ftpgroup['gid']
    members users.map { |u| u['id'] }
  end

  template ::File.join(node.vsftpd.config_path, "vsftpd.user_list") do
    source "vsftpd/vsftpd.user_list.erb"
    variables({ users: users })
    notifies :restart, "service[vsftpd]"
  end
end
