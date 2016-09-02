#!/usr/bin/env ruby
# Generates the html documentation from the markdown files in the GitLab repo.
# By default, the site is built in /srv/doc-gitlab-com. This location can be
# overridden with the SITE_PATH environment variable.
#
# By default, this script will not create console output. If you want to see
# progress indicators, set the `PROGRESS` environment variable:
#
#   PROGRESS=1 ./generate.rb
#

EXCLUDE_PATHS = %w{install/packages.md}

def main
  $progress.puts 'Generating HTML documentation from Markdown'

  require 'fileutils'
  require 'find'

  root_path = File.expand_path('../../', __FILE__)
  doc_path = File.join(root_path, 'doc/')
  site_path = ENV['SITE_PATH'] || '/tmp/gitlab/docs'

  $progress.puts 'Deleting files that should be excluded'
  EXCLUDE_PATHS.each do |excluded_path|
    delete_command = %W(find #{doc_path} -path *#{excluded_path} -delete)
    delete_command << '-print' if ENV['PROGRESS']
    system(*delete_command)
  end

  doc_directories = Find.find(doc_path).map do |path|
    File.dirname(path.sub(doc_path, ''))
  end.uniq

  all_directories = doc_directories.unshift('') # Also add the root README.md, must be the first one.

  $progress.print "Generating pages: "
  all_directories.each do |directory|
    destination_dir = [site_path, directory].join('/')
    FileUtils.rm_rf(destination_dir) if File.exist?(destination_dir)
    FileUtils.mkdir_p(destination_dir)
    path = File.join(doc_path, directory, "*.md")

    Dir[path].each do |markdown_file|
      template_path = File.join(root_path, 'scripts/doc-template.html')
      # Because the README files are like tables of contents, don't add
      # another table of contents to them.
      toc = markdown_file.include?('README') ? nil : '--toc'
      html = `pandoc #{toc} --template #{template_path} --from markdown_github-hard_line_breaks #{markdown_file}`

      html.gsub!(/href="(\S*)"/) do |result| # Fetch all links in the HTML Document
        if /http/.match(result).nil? # Check if link is internal
          result.gsub!(/\.md/, '.html') # Replace the extension if link is internal
        end
        result
      end

      filename = File.basename(markdown_file)

      html_filename = filename.gsub('.md', '.html')
      File.open(File.join(site_path, directory, html_filename), 'w') {
        |file| file.write(html)
      }

      $progress.print '.'
    end
  end
  $progress.puts '' # Create a newline

  $progress.print "Copying png images: "
  all_directories.each do |directory|
    destination_dir = [site_path, directory].join('/')
    path = File.join(doc_path, directory, "*.png")

    Dir[path].each do |src_image|
      image_basename = File.basename(src_image)
      dest_image = File.join(site_path, directory, image_basename)
      FileUtils.copy_file(src_image, dest_image)
      $progress.print '.'
    end
  end

  $progress.puts '' # Create a newline
  $progress.puts 'Done'
end

if ENV['PROGRESS']
  $progress = $stdout
else
  require 'stringio'
  $progress = StringIO.new
end

main
