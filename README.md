# ScrubRb

Pure-ruby polyfill of MRI 2.1 String#scrub, for ruby 1.9 and 2.0 any interpreter

[![Build Status](https://travis-ci.org/jrochkind/scrub_rb.png?branch=master)](https://travis-ci.org/jrochkind/scrub_rb) [![Gem Version](https://badge.fury.io/rb/scrub_rb.png)](http://badge.fury.io/rb/scrub_rb)

## Installation

Add this line to your application's Gemfile:

    gem 'scrub_rb'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scrub_rb


## What it is

Ruby 2.1 introduces String#scrub, a method to replace bytes in a string that are invalid for it's specified encoding.
See docs in [MRI ruby source](https://github.com/ruby/ruby/blob/1e8a05c1dfee94db9b6b825097e1d192ad32930a/string.c#L7772)

If you need String#scrub in MRI ruby 2.0, you can use the [string-scrub gem](https://github.com/hsbt/string-scrub), which provides a backport of the C code from MRI ruby 2.1 into MRI 2.0.

What if you need this functionality in ruby 1.9, in jruby in 1.9 or 2.0 modes, or in
any other ruby platform that does not (or does not yet) support String#scrub?  What if
you need to write code that will work on any of these platforms?

This gem provides a pure-ruby implementation of `String#scrub` and `#scrub!`, monkey-patched into
String, that should work on any ruby platform.  It will only monkey-patch String
if String does not already have a #scrub method -- so it's safe to include
this gem in multi-platform code, when the code runs on ruby 2.1, String#scrub will
still be the original stdlib implementation.

~~~ruby
# Encoding: utf-8

"abc\u3042\x81".scrub #=> "abc\u3042\uFFFD"
"abc\u3042\x81".scrub("*") #=> "abc\u3042*"
"abc\u3042\xE3\x80".scrub{|bytes| '<'+bytes.unpack('H*')[0]+'>' } #=> "abc\u3042<e380>"
~~~

## Performance

This pure ruby implementation is about an order of magnitude slower than stdlib String#scrub on ruby 2.1, or than `string-scrub` C gem on MRI 2.0.   For most applications, string-scrubbing will probably be a small portion of total execution time, is still fairly fast, and hopefully won't be a problem.

## Discrepency with MRI 2.1 String#scrub

If there is a sequence of multiple contiguous invalid bytes in a string, should the entire block be replaced with only one replacement, or should each invalid byte be replaced with a replacement?

I have not been able to understand the logic MRI 2.1 uses to divide contiguous invalid bytes into
certain sub-sequences for replacement, as represented in the [test suite](https://github.com/ruby/ruby/blob/3ac0ec4ecdea849143ed64e8935e6675b341e44b/test/ruby/test_m17n.rb#L1505).  The test suite may be suggesting that the examples are from unicode documentation, but I wasn't able to find such documentation to see if it shed any light on the matter.

`scrub_rb` always combines contiguous invalid bytes into a single replacement. As a result, it fails several tests from the original String#scrub test suite, which want other divisions of contiguous invalid bytes. I've altered our local tests for our current behavior.

Beware of this potential difference when using the block form of #scrub especially -- you may get a different number of calls with sequence of invalid bytes divided into different substrings with `scrub_rb` as compared to official MRI 2.1 String#scrub or `string-scrub`.

For most uses, this discrepency is probably not of consequence.

If anyone can explain whats going on here, I'm very curious! I can't read C very well to try and figure it out from source.

## JRuby in earlier versions may raise

Use Jruby 1.7.11 or later to avoid [a known bug](https://github.com/jruby/jruby/issues/1361#issuecomment-35776377) that made JRuby raise exceptions on certain unusual illegal byte combinations and prevent scrub_rb from scrubbing them. 

## Contributions

Pull requests or suggestions welcome, especially on performance, on JRuby issue, and on discrepencies with official String#scrub.
