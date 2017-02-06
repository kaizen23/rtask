require 'json'
require 'bunny'
class Chat
  #The method of displaying a name of user and a message on the terminal
  def display_message(user, message)
    puts "#{user}: #{message}"
  end
#The constructor initializes the parameters needed to connect to the chat.Creates a class object Bunny.Library Bunny is a client RabbitMQ
  def initialize
    print "Type in your name: "
    @current_user = gets.strip
    puts "Hi #{@current_user}, you just joined a chat room! Type your message in and press enter."

    conn = Bunny.new
    conn.start

    @channel = conn.create_channel
    @exchange = @channel.fanout("super.chat")

    listen_for_messages
  end
  #Method listens for new messages appearing on the channel.Then decodes format JSON, displays a name of user and message on the terminal.
  def listen_for_messages
    queue = @channel.queue("")

    queue.bind(@exchange).subscribe do |delivery_info, metadata, payload|
      data = JSON.parse(payload)
      display_message(data['user'], data['message'])
    end
  end
  #Method of encoding to JSON the name of the user with the message.After that  publishing this data in the channel.
  def publish_message(user, message)
    queue = @channel.queue("")
    data = JSON.generate(user: user, message: message)
    @exchange.publish(data)
  end
  #Method that takes a message typed in the terminal, then sending it to the channel chat
  def wait_for_message
    message = gets.strip
    publish_message(@current_user, message)
    wait_for_message
  end

end
  #Launch the chat.
chat = Chat.new
chat.wait_for_message
