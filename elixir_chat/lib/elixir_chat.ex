defmodule ElixirChat do
  #This is a starting the method.The Initialization parameters of connection to the chat.And also invoke two methods of listening and downloading information from the keyboard.
  def start do
    user = IO.gets("Type in your name: ") |> String.strip
    IO.puts "Hi #{user}, you just joined a chat room! Type your message in and press enter."

    {:ok, conn} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(conn)
    {:ok, queue_data } = AMQP.Queue.declare channel, ""

    AMQP.Exchange.fanout(channel, "super.chat")
    AMQP.Queue.bind channel, queue_data.queue, "super.chat"

    spawn (fn -> listen_for_messages(channel, queue_data.queue ) end)
    wait_for_message(user, channel)
  end
  #The method of displaying a name of user and a message on the terminal
  def display_message(user, message) do
    IO.puts "#{user}: #{message}"
  end
  #Method that takes a message typed in the terminal, then sending it to the channel chat
  def wait_for_message(user, channel) do
    message = IO.gets("") |> String.strip
    publish_message(user, message, channel)
    wait_for_message(user, channel)
  end
  #Method listens for new messages appearing on the channel.Then decodes format JSON, displays a name of user and message on terminal.
  def listen_for_messages(channel, queue_name) do
    AMQP.Basic.consume(channel,queue_name,nil,no_ack: true)

    receive do
      {:basic_deliver, payload, _meta}->
      {status, list} = JSON.decode(payload)
      display_message(list["user"], list["message"])
      listen_for_messages(channel, queue_name) 
    end
  end
  #Method of encoding to JSON the name of the user with the message.After that  publishing this data in the channel.
  def publish_message(user, message, channel) do
    { :ok, data } = JSON.encode([user: user, message: message])
    AMQP.Basic.publish channel, "super.chat", "", data
  end

end
  #Launch the chat.
ElixirChat.start
