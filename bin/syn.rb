#!/usr/bin/env ruby
# 1.9 adds realpath to resolve symlinks; 1.8 doesn't
# have this method, so we add it so we get resolved symlinks
# and compatibility
unless File.respond_to? :realpath
  class File #:nodoc:
    def self.realpath path
      return realpath(File.readlink(path)) if symlink?(path)
      path
    end
  end
end
$: << File.expand_path(File.dirname(File.realpath(__FILE__)) + '//..//lib')
require 'rubygems'
require 'gli'
require 'syn_version'

include GLI::App

config_file File.join(ENV['HOME'],'.syn.rc.yaml')


program_desc 'Command Suite for the Synoptix Reporting Tool'

version Syn::VERSION

def buildClasspath(directory)
    directory = File.expand_path(directory)
    classpath = "-classpath #{directory}" 
    Dir.glob("#{directory}/*.jar") do |fname|
        classpath = classpath + ":" + fname
    end
    Dir.glob("#{directory}/*.zip") do |fname|
        classpath = classpath + ":" + fname
    end
    classpath
    
end

def runJava(global_options, mainClass)
    classpath = buildClasspath(global_options[:d])
    memory = global_options[:m]
    user_dir = global_options[:u] 
    Dir.chdir global_options[:d]
    `java -Xmx#{memory} -Duser.home=#{user_dir} #{classpath} #{mainClass}`
end

desc 'Base directory to run Synoptix'
default_value './'
arg_name 'Directory'
flag [:d,:directory]

desc 'User directory to run Synoptix'
default_value File.expand_path('~')
arg_name 'User Directory'
flag [:u,:userdir]


desc 'Max memory setting'
default_value '512m'
arg_name 'Max Memory'
flag [:m,:memory]


desc 'Launch Synoptix Login'
arg_name 'Describe arguments to login here'
command :login do |c|
    c.desc 'Automatically login'
    c.switch [:a,:auto]

  
    c.action do |global_options,options,args|
        command = 'com.compusoftdevelopment.workbench.Login '
        if options[:a]
            if args.empty?
                command = command + 'user pass'
            else
                command = command + args.join(' ')
            end
        end
        runJava(global_options, command)
    end
end

desc "Runs the Synoptix Report Runner.  If the report you are running contains any Variable parameters, and you would like to have those parameters defaulted, you can enter the defaulted parameters as follows: parameterName=”value”. The parameter name is the name that you would see when you modify the Sphere properties. In the case below you would enter the following: “Customer #=value” Please Note: Because the parameterName in this case contains a space, the entire string is surrounded by quotes.
"
arg_name 'parameters'
command :runner do |c|
    
    c.desc 'Report to Run'
    c.arg_name 'Report Name'
    c.flag [:r,:report]
    
    c.desc 'Date to run Report(YYYY-MM-DD)'
    c.arg_name 'Report Date'
    c.default_value 'today'
    c.flag [:d,:date]
    
    c.action do |global_options,options,args|
        report_name = options[:r]
        report_date = options[:d]
        puts report_date
      command = "com.compusoftdevelopment.runner.SingleReportRunner"
        if options[:report_name]
        command = command + "report='#{report_name}' date=#{report_date}"
      end
      if not args.empty?
          command = command + ' ' + args.join(' ')
      end

      runJava(global_options, command)
  end
end

desc 'Launch the Report Scheduling Server'
arg_name 'Describe arguments to server here'
command :server do |c|
    c.desc 'Run with no GUI'
    c.switch [:s,:server]
  c.action do |global_options,options,args|
      command = 'com.compusoftdevelopment.server.SynoptixServer'
      if options[:s]
            command = command + ' server'
      end
      runJava(global_options, command)
  end
end

pre do |global,command,options,args|
  # Pre logic here
  # Return true to proceed; false to abort and not call the
  # chosen command
  # Use skips_pre before a command to skip this block
  # on that command only
  true
end

post do |global,command,options,args|
  # Post logic here
  # Use skips_post before a command to skip this
  # block on that command only
end

on_error do |exception|
  # Error logic here
  # return false to skip default error handling
  true
end

exit run(ARGV)
