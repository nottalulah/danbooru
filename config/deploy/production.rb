set :user, "albert"
server "sonohara.donmai.us", :roles => %w(web app db), :primary => true, :user => "albert"
server "hijiribe.donmai.us", :roles => %w(web app), :user => "albert"
