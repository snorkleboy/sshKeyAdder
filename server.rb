require 'socket'
require 'thread'

require 'json'

include Socket::Constants


class Server
    def initialize(port, host)
        @server = TCPServer.new port
        puts "listening"
        @incorrectAttempts = 0
        @password = File.open('password', &:readline)
        start
    end

    def start
        while (@incorrectAttempts < 3)
            client = @server.accept
            begin
                shakeAndBake(client)
            rescue => exception
                puts exception
            end
        end
        @server.close
    end
    def shakeAndBake(client)
        if (passwordChallenge(client))
            if (textChallenge(client))
                getSaveKey(client)
                client.puts "SUCCESS"
                client.close
            else
                client.puts "wrong code"
                @incorrectAttempts = @incorrectAttempts + 1
            end  
        else
            puts "wrong password"
            @incorrectAttempts = @incorrectAttempts + 1
        end
    end
    def passwordChallenge(client)
        passwrd = getPassword(client)
        return passwrd == @password
    end
    def getPassword(client)
        client.puts "Hi, please enter password"
        passwrd = client.gets.chomp
    end
    def textChallenge(client)
        #make text message challenge
        challenge = "#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}#{rand(9)}"
        `#{makeBashEmail(challenge)}`
        #inform client
        client.puts "sending a code to a registered phone number, please enter it when you receive it"  
        returnChallenge = client.gets.chomp
        return challenge == returnChallenge
    end
    def makeBashEmail(challenge)
        toField = "To:someone@txt.att.net"
        fromField = "From:timkharshan@hotmail.com"
        subjectField = "Subject: subject"
        ssmtp = "ssmtp 9253305948@txt.att.net"
        command = "echo '#{toField}\n#{fromField}\n#{subjectField}\n\n#{challenge}'| #{ssmtp} " 
    end
    def getSaveKey(client)
        key = getKey(client)
        `echo "\n#{key}">> ~/.ssh/authorized_keys `
    end
    
    def getKey(client)
        client.puts "enter your public key as a single line"
        key = client.gets.chomp
    end
end
server = Server.new(ARGV[0] || 9876, ARGV[1] || 'localhost')