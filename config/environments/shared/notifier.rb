module GocongressNotifier
  def self.use_exception_notifier_middleware config
    config.middleware.use ExceptionNotification::Rack,
      :email => {
        :email_prefix => "[USGC] ",
        :sender_address => 'usgcwebsite@gmail.com',
        :exception_recipients => 'jared@jaredbeck.com'
      }
  end
end
