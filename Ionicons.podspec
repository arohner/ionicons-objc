Pod::Spec.new do |spec|
  spec.name     = 'Ionicons'
  spec.version  = '1.3.5'
  spec.authors   = { 'Connor Grady' => 'conair360@gmail.com' }
  spec.license  = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage = 'https://github.com/itsjustcon/ionicons-objc'
  spec.summary  = 'Use the beautiful Ionicons font (http://ionicons.com/) in your native Objective-C projects.'
  spec.source   = { :git => 'https://github.com/itsjustcon/ionicons-objc.git', :tag => "v#{spec.version}" }
  spec.platform = :ios, '5.0'
  #spec.source_files = '*.{h,m,plist}'
  #spec.resources = [ 'Ionicons.plist' ]
  spec.source_files = '*.{h,m}'
  spec.resources = [ 'ionicons.ttf' ]
  #spec.resource_bundles = { 'Ionicons' => ['ionicons.ttf'] }
  spec.requires_arc = true
  #spec.xcconfig = { 'INFOPLIST_FILE' => 'Ionicons.plist' }

  spec.post_install do |library_representation|
    require 'rexml/document'

    library = library_representation.library
    proj_path = library.user_project_path
    proj = Xcodeproj::Project.new(proj_path)
    target = proj.targets.first # good guess for simple projects

    info_plists = target.build_configurations.inject([]) do |memo, item|
      memo << item.build_settings['INFOPLIST_FILE']
    end.uniq
    info_plists = info_plists.map { |plist| File.join(File.dirname(proj_path), plist) }

    resources = library.file_accessors.collect(&:resources).flatten
    fonts = resources.find_all { |file| File.extname(file) == '.otf' || File.extname(file) == '.ttf' }
    fonts = fonts.map { |f| File.basename(f) }

    info_plists.each do |plist|
      doc = REXML::Document.new(File.open(plist))
      main_dict = doc.elements["plist"].elements["dict"]
      app_fonts = main_dict.get_elements("key[text()='UIAppFonts']").first
      if app_fonts.nil?
        elem = REXML::Element.new 'key'
        elem.text = 'UIAppFonts'
        main_dict.add_element(elem)
        font_array = REXML::Element.new 'array'
        main_dict.add_element(font_array)
      else
        font_array = app_fonts.next_element
      end

      fonts.each do |font|
        if font_array.get_elements("string[text()='#{font}']").empty?
          font_elem = REXML::Element.new 'string'
          font_elem.text = font
          font_array.add_element(font_elem)
        end
      end

      doc.write(File.open(plist, 'wb'))
    end
  end

end