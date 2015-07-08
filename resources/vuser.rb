actions :create, :delete
default_action :create

attribute :password,    kind_of:String, required:true
attribute :home_dir,    kind_of:String, default: lazy { |r| "#{node.scpr_ftp.home}/#{r.name}" }
attribute :chroot,      kind_of:[TrueClass,FalseClass], default:true
attribute :ip_range,    kind_of:String

attribute :manage_home, kind_of:[TrueClass,FalseClass], default:false
