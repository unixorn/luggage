#!/usr/bin/ruby
#
#   Copyright 2009 Joe Block <jpb@ApesSeekingKnowledge.net>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'syslog'

class HookRunner

  def initialize(dir_path, prefix)
    @dialog_background_image="/etc/hooks/hook_background.jpg"
    @dir_path = dir_path
    @hook_d = "/etc/hooks"
    @paranoid = false
    @prefix = prefix
  end

  def log_message(msg)
    Syslog.notice(msg)
    puts msg
  end

  def ihook_setup
    # become front application, disable UI and show background image and barberpole
    puts "%WINDOWSIZE 680 448"
    if File.size?(@dialog_background_image)
      puts "%BACKGROUND #{@dialog_background_image}"
    end
    puts "%WINDOWLEVEL HIGH"
    puts "%BECOMEKEY"
    puts "%UIMODE AUTOCRATIC"
    puts "%BEGINPOLE"
  end

  def ihook_teardown
    puts "prefix: #{@prefix}"
    log_message("Finishing hooks")
    puts "%ENDPOLE"
  end

  def run_all_scripts()
    if ! File.directory?(@dir_path)
      log_message("#{@dir_path} not a directory.")
      exit 1
    end
    command_line_args = ARGV.join(' ')
    Dir["#{@dir_path}/#{@prefix}*"].each do |hook|
      if File.executable?(hook)
        puts "Running #{hook} #{command_line_args}"
        system("#{hook} #{command_line_args}")
        exit_value = $?.exitstatus
        if exit_value > 0
          log_message("#{hook} failed with exit code #{exit_value}")
          if @paranoid
            exit exit_value
          end
        end
      end
    end
  end

end
