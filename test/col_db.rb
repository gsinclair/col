D "Col::DB" do
  D "method?" do
    D "given symbol" do
      T Col::DB.method?(:yellow)
      T Col::DB.method?(:blink)
      T Col::DB.method?(:on_cyan)
    end
    D "given string" do
      T Col::DB.method?("yellow")
      T Col::DB.method?("blink")
      T Col::DB.method?("on_cyan")
    end
  end
end
