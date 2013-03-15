module Niouz
  #based on http://tools.ietf.org/html/rfc4643
  module AuthCommands
    #http://tools.ietf.org/html/rfc4643#section-2.3
    #TODO: force user to TLS
    def authinfo_user(username)
      if authenticated?
        r(502)
      else
        @username_try=username
        r(381) # might also be 281 if no passwd required or a 483 for tls
      end
    end

    def authinfo_pass(password)
      if @username_try
        if User.auth(@username_try, password)
          @user=@username_try
          r(281)
        else
          @username_try=nil #reset sequence
          r(481)
        end
      else
        r(482)
      end
    end

    private
    def user
      @user ||= User.guest
    end

    def authenticated?
      !user.guest
    end
  end
end