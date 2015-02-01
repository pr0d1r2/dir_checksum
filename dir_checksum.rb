#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

start_dir = Dir.pwd

case `uname`
when 'Darwin'
  @md5cmd = 'md5'
else
  @md5cmd = 'md5sum'
end

def md5(file)
  if file.include?("'")
    `#{@md5cmd} "#{file}" | cut -b1-32`.strip
  else
    `#{@md5cmd} '#{file}' | cut -b1-32`.strip
  end
end

ARGV.each do |dir|
  checksum_file = "#{dir}.dir_checksum.yml"
  checksum_file_ok = "#{dir}.dir_checksum.ok"
  if File.file?(checksum_file)
    if File.directory?(dir)
      if File.file?(checksum_file_ok)
        puts "#{dir} : [ALL OK confirmed before]"
        exit 0
      else
        dir_data = YAML.load_file(checksum_file)
        Dir.chdir(dir)
        dir_data.each do |file,data|
          if File.size(file) == data["size"]
            puts "#{file} [SIZE OK]"
          else
            puts "#{file} [SIZE BAD]"
            exit 1
          end
        end
        dir_data.each do |file,data|
          if md5(file) == data["md5sum"]
            puts "#{file} [md5sum OK]"
          else
            puts "#{file} [md5sum BAD]"
            exit 2
          end
        end
        Dir.chdir('..')
        FileUtils.touch(checksum_file_ok)
        Dir.chdir(start_dir)
      end
    end
  else
    if File.directory?(dir)
      Dir.chdir(dir)
      dir_data = Hash[
        Dir.glob("**/*").map do |file|
          puts file
          if File.file?(file)
            [
              file, {
                "size" => File.size(file),
                "md5sum" => md5(file)
              }
            ]
          end
        end
      ]
    else
      raise "There is no directory: #{dir}"
    end
    Dir.chdir(start_dir)
    File.open("#{dir}.dir_checksum.yml", 'w+') { |f| f.write(dir_data.to_yaml) }
  end
end
