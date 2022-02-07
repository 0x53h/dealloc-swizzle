class Object

  def deal_log
    puts "-- DEALLOC #{self.class.name} -- #{self.to_s}"
  end

end
