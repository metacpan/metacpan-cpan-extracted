describe Array do
    before :all do
        puts "OUTER BEFORE"
    end
    after :all do
        puts "OUTER AFTER"
    end
    before :each do
        puts "OUTER BEFORE_EACH"
    end 
    after :each do
        puts "OUTER AFTER_EACH"
    end 

    it {
        puts "test p"
    }

    context {
        before :all do
            puts "BEFORE_ALL INNER"
        end 
        before :each do
            puts "BEFORE_EACH INNER"
        end 
        it {
            puts "test y"
        }
        it {
            puts "test z"
        }
        after :each do
            puts "AFTER_EACH INNER"
        end 
        after :all do
            puts "AFTER_ALL INNER"
        end 
    }
end
