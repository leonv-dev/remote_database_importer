class Colorize
  def self.red(text)
    "\033[31m#{text}\033[0m"
  end

  def self.green(text)
    "\e[32m#{text}\e[0m"    
  end

  def self.blue(text)
    "\e[94m#{text}\e[0m"
  end
end