#!/usr/bin/env ruby

require 'open-uri'
require 'json'

BUCKET = "artstech"
INCOMING_DIR = "incoming"

system("mkdir output")

def most_recent_file(dir)
  Dir.glob("#{dir}/*").max { |a,b|
    (File.mtime(a) <=> File.mtime(b))
    #(File.mtime(File.join(dir,a)) <=> File.mtime(File.join(dir,b)))
  }
end

def current_key
  open('http://styleblaster.net/bgz/current') { |f|
    return f.read
  }
end

def convert(jpg, key)
  watermark = "watermarks/watermark_#{rand(6)}.png"
  output = Time.now.strftime("#{BUCKET}-%Y-%m-%d-%H-%M-%S.jpg")
  cmd  = "convert \\( backgrounds/#{key}.jpg -resize x600 \\)"
  cmd += " #{watermark} -geometry +20+15 -gravity NorthEast -compose Over -composite"
  cmd += " \\( #{jpg} -gravity Center"
  #cmd += " -fuzz 8% -transparent \\#34643b"
  #cmd += " -fuzz 4% -transparent \\#294f2e"
  #cmd += " -fuzz 4% -transparent \\#19351e"
#  cmd += " -fuzz 4% -transparent \\#5c6b4a"
#  cmd += " -fuzz 4% -transparent \\#576043"
#  cmd += " -fuzz 8% -transparent \\#497f5b"
#  cmd += " -fuzz 8% -transparent \\#3e7250"
#  cmd += " -fuzz 8% -transparent \\#2c563a"
#  cmd += " -fuzz 8% -transparent \\#1f442e"
#  cmd += " -fuzz 8% -transparent \\#15411f"
  cmd += " -fuzz 6% -transparent \\#143c2c"
  cmd += " -fuzz 4% -transparent \\#0c2412"
  #cmd += " -normalize -resize 600x -rotate 270 \\)"
  cmd += " -normalize -resize x600 \\)"
  cmd += " -compose Over -composite -normalize -quality 88 output/#{output}"
  system(cmd)
  return output
#  return nil
end

def upload(jpg)
  if not jpg.nil? and File.exists?("output/#{jpg}")
    cmd = "curl -i -F test=@output/#{jpg} http://styleblaster.net/upload/artstech"
    system(cmd)
  end
end

old_jpg = nil
loop {
  jpg = most_recent_file( INCOMING_DIR )
  key = current_key()
  puts "current key: #{key} ... #{jpg}"

  if jpg != old_jpg
    out = convert(jpg, key)
    upload(out)
  end

  sleep(1)
  old_jpg = jpg
}

