require "scrub_rb/version"

module ScrubRb

  # static function implementation of String#scrub, where
  # first arg is the string.
  #
  #     ScrubRb.scrub("abc\u3042\x81") #=> "abc\u3042\uFFFD"
  #     ScrubRb.scrub("abc\u3042\x81", "*") #=> "abc\u3042*"
  #     ScrubRb.scrub("abc\u3042\xE3\x80") {|bytes| '<'+bytes.unpack('H*')[0]+'>' } #=> "abc\u3042<e380>"
  def self.scrub(str, replacement=nil, &block)
    return str if str.nil?

    if replacement.nil? && ! block_given?
      replacement =
         # UTF-8 for unicode replacement char \uFFFD, encode in
         # encoding of input string, using '?' as a fallback where
         # it can't be (which should be non-unicode encodings)
         "\xEF\xBF\xBD".force_encoding("UTF-8").encode( str.encoding,
                                                  :undef => :replace,
                                                  :replace => '?' )
    end

    result          = ""
    bad_chars       = ""

    str.chars.each do |c|
      if c.valid_encoding?
        scrub_replace(result, bad_chars, replacement, block)
        result << c
      else
        bad_chars << c
      end
    end
    scrub_replace(result, bad_chars, replacement, block)

    return result
  end

  private
  def self.scrub_replace(result, bad_chars, replacement, block)
    if bad_chars.length > 0
      if block
        result << block.call(bad_chars)
      else
        result << replacement
      end
      bad_chars.clear
    end
  end

end
