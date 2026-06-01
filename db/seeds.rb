user = User.where(email: 'dev@example.com').first ||
       User.create!(name: 'Dev User', email: 'dev@example.com',
                    password: 'password', password_confirmation: 'password')

[
  { name: 'GitHub',  username: 'devuser',           password: 'mypassword',  url: 'https://github.com',         note: 'Personal account' },
  { name: 'Gmail',   username: 'devuser@gmail.com',  password: 'p@ssw0rd!',  url: 'https://mail.google.com',    note: '' },
  { name: 'AWS',     username: 'admin',              password: 'S3cr3t#Key', url: 'https://aws.amazon.com',     note: 'Root account' },
].each do |attrs|
  next if Credential.where(name: attrs[:name], user: user).exists?

  Credential.create!(attrs.merge(user: user))
end
