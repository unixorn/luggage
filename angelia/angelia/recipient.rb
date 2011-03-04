module Angelia
    # A simple class to contain recipients, recipients are provided in the form
    # twitter://user this class just parses that and provides a protocol and user
    # breakdown.
    class Recipient
        attr_reader :protocol, :user

        def initialize(recipient)
            if recipient =~ /(.+)\:\/\/(.+)/
                @protocol = $1
                @user = $2

                Angelia::Util.debug("Recipient #{recipient} has protocol #{@protocol} and user #{@user}")
            else
                raise("Recipient #{recipient} is not in the correct format")
            end
        end

        def to_s
            "#{@protocol}://#{user}"
        end
    end
end

# vi:tabstop=4:expandtab:ai
