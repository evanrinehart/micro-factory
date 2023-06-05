class SerialNo
  
  @@counter = 0

  def self.mint
    @@counter += 1
    return @@counter
  end

end
