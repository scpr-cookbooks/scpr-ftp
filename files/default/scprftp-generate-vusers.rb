#!/opt/chef/embedded/bin/ruby

USERS_DIR   = "/etc/pure-ftpd/vusers.d"
USERS_FILE  = "/etc/pure-ftpd/pureftp.passwd"
USERS_DB    = "/etc/pure-ftpd/pureftp.db"

# -- load all users -- #

users = {}

Dir.glob("#{USERS_DIR}/*.user").each do |f|
  # read the password line
  u = File.read(f)

  # pull the username
  username = u.split(":")[0]

  users[username] = u
end

# -- write out our sorted file -- #

File.open(USERS_FILE,"w") do |out_f|
  users.sort.each do |username,u|
    out_f.puts u
  end
end

# -- Rebuild the database -- #

`pure-pw mkdb #{USERS_DB} -f #{USERS_FILE}`