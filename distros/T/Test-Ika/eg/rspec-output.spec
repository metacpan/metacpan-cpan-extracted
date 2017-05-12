
class MessageFilter
    def initialize(word)
        @word = word
    end
    def detect?(text)
        text.include?(@word)
    end
end

describe MessageFilter do
    subject { MessageFilter.new('foo') }
    it { should be_detect('hello from foo') }
    it { should_not be_detect('hello, world!') }
end

