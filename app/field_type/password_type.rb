# puts OpenSSL::Cipher.ciphers
class PasswordType

  attr_reader :password, :crypted

  def initialize(crypted)
    @password = PasswordType.decrypt(crypted) if crypted
  end

  # Converts an object of this instance into a database friendly value.
  def mongoize
    @crypted = PasswordType.encrypt(@password)
    @crypted
  end

  class << self

    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      PasswordType.new(object).password
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      case object
      when PasswordType then object.mongoize
      else encrypt(object)
      end
    end

    def encrypt(password)
      return "" if password.blank?
      cipher = OpenSSL::Cipher::AES256.new :CBC
      cipher.encrypt
      iv = cipher.random_iv
      puts "ENCRYPT -----------"
      puts ENV["SECRET_PM"]
      puts Encoding.default_external
      cipher.key = ENV["SECRET_PM"]
      cipher_text = cipher.update(password) + cipher.final
      cipher_text = Base64.encode64(cipher_text).encode('utf-8')
      iv = Base64.encode64(iv).encode('utf-8')
      result = [cipher_text, iv]
      puts result
      result
    end

    def decrypt(cipher)
      return "" if cipher.length != 2
      decipher = OpenSSL::Cipher::AES256.new :CBC
      decipher.decrypt
      decipher.iv = Base64.decode64 cipher[1].encode('ascii-8bit') # previously saved
      puts "C§IAOOOO -----------"
      puts ENV["SECRET_PM"]
      decipher.key = ENV["SECRET_PM"]
      plain_text = decipher.update(Base64.decode64 cipher[0].encode('ascii-8bit')) + decipher.final
      puts plain_text
      plain_text
    end

    # Converts the object that was supplied to a criteria and converts it
    # into a database friendly form.
    def evolve(object)
      case object
      when PasswordType then object.mongoize
      else object
      end
    end
  end
end