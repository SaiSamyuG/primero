# -*- coding: utf-8 -*-
require 'spec_helper'

describe "record field model" do

  before :each do
    FormSection.all.each { |form| form.destroy }
    @field_name = "gender"
    @field = Field.new :name => "gender", :display_name => @field_name, :option_strings => "male\nfemale", :type => Field::RADIO_BUTTON
  end

  describe '#name' do
    it "should not be generated when provided" do
      field = Field.new :name => 'test_name'
      field.name.should == 'test_name'
    end
  end

  it "converts field name to a HTML tag ID" do
    @field.tag_id.should == "child_#{@field_name}"
  end

  it "converts field name to a HTML tag name" do
    @field.tag_name_attribute.should == "child[#{@field_name}]"
  end

  it "returns the html options tags for a select box with default option '(Select...)'" do
    @field = Field.new :type => Field::SELECT_BOX, :display_name => @field_name, :option_strings_text => "option 1\noption 2"
    @field.select_options("", []).should == [["(Select...)", ""], ["option 1", "option 1"], ["option 2", "option 2"]]
  end

  it "should have form type" do
    @field.type.should == "radio_button"
    @field.form_type.should == "multiple_choice"
  end

  it "should create options from text" do
    field = Field.new :display_name => "something", :option_strings_text => "tim\nrob"
    field['option_strings_text'].should == nil
    field.option_strings.should == ["tim", "rob"]
  end

  it "should have display name with hidden text if not visible" do
    @field.display_name = "pokpok"
    @field.visible = false

    @field.display_name_for_field_selector.should == "pokpok (Hidden)"

  end

  describe "valid?" do

    it "should not allow blank display name" do
      field = Field.new(:display_name => "")
      expect(field.valid?).to be false
      expect(field.errors[:display_name].first).to eq "The name of the base language 'en' can not be blank"
    end

    it "should not allows empty field display_name of field base language " do
      field = Field.new(:display_name_en => 'English', :display_name_zh=>'Chinese')
      I18n.default_locale='zh'
      expect {
        field[:display_name_en]=''
        field.save!
      }.to raise_error
    end

    it "should not allow display name without alphabetic characters" do
      field = Field.new(:display_name => "!@£$@")
      field.valid?.should == false
      field.errors[:display_name].should include("Display name must contain at least one alphabetic characters")
    end

    it "should not allow blank name" do
      field = Field.new(:display_name => "ABC 123", :name => "")
      expect(field.valid?).to be false
      expect(field.errors[:name].first).to eq "Field name must not be blank"
    end

    it "should not allow capital letters in name" do
      field = Field.new(:display_name => "ABC 123", :name => "Abc_123")
      expect(field.valid?).to be false
      expect(field.errors[:name].first).to eq "Field name must contain only lower case alphabetic characters, numbers, and underscores"
    end

    it "should not allow special characters in name" do
      field = Field.new(:display_name => "ABC 123", :name => "a$bc_123")
      expect(field.valid?).to be false
      expect(field.errors[:name].first).to eq "Field name must contain only lower case alphabetic characters, numbers, and underscores"
    end

    it "should not allow name to start with a number" do
      field = Field.new(:display_name => "ABC 123", :name => "1abc_123")
      expect(field.valid?).to be false
      expect(field.errors[:name].first).to eq "Field name cannot start with a number"
    end

    it "should allow alphabetic characters numbers and underscore in name" do
      field = Field.new(:display_name => "ABC 123", :name => "abc_123")
      expect(field.valid?).to be true
    end

    it "should allow alphabetic only in name" do
      field = Field.new(:display_name => "ABC 123", :name => "abc")
      expect(field.valid?).to be true
    end

    it "should allow alphabetic and numeric only in name" do
      field = Field.new(:display_name => "ABC 123", :name => "abc123")
      expect(field.valid?).to be true
    end

    it "should validate unique within form" do
      form = FormSection.new(:fields => [Field.new(:name => "other", :display_name => "other")] )
      field = Field.new(:display_name => "other", :name => "other")
      form.fields << field

      field.valid?
      field.errors[:name].should ==  ["Field already exists on this form"]
      field.errors[:display_name].should ==  ["Field already exists on this form"]
    end

    it "should validate radio button has at least 2 options" do
      field = Field.new(:display_name => "test", :option_strings => ["test"], :type => Field::RADIO_BUTTON)

      field.valid?
      field.errors[:option_strings].should ==  ["Field must have at least 2 options"]
    end

    it "should validate checkbox has at least 1 option to be checked" do
      field = Field.new(:display_name => "test", :option_strings => nil, :type => Field::CHECK_BOXES)

      field.valid?
      field.errors[:option_strings].should ==  ["Checkbox must have at least 1 option"]
    end

    it "should validate select box has at least 2 options" do
      field = Field.new(:display_name => "test", :option_strings => ["test"], :type => Field::SELECT_BOX)

      field.valid?
      field.errors[:option_strings].should ==  ["Field must have at least 2 options"]
    end

    # Test no longer valid. Now allowing sharing of fields

    # it "should validate unique within other forms" do
    #   other_form = FormSection.new(:name => "test form", :fields => [Field.new(:name => "other_test", :display_name => "other test")] )
    #   other_form.save!

    #   form = FormSection.new
    #   field = Field.new(:display_name => "other test", :name => "other_test")
    #   form.fields << field

    #   field.valid?
    #   field.errors[:name].should ==  ["Field already exists on form 'test form'"]
    # end
  end

  describe "save" do
    it "should set visible" do
      field = Field.new(:name => "diff_field", :display_name => "diff_field", :visible => "true")
      form = FormSection.new(:fields => [field], :name => "test_form")

      form.save!

      form.fields.first.should be_visible
    end
  end

  describe "default_value" do
    it "should be empty string for text entry, radio, audio, photo and select fields" do
      Field.new(:type=>Field::TEXT_FIELD).default_value.should == ""
      Field.new(:type=>Field::NUMERIC_FIELD).default_value.should == ""
      Field.new(:type=>Field::TEXT_AREA).default_value.should == ""
      Field.new(:type=>Field::DATE_FIELD).default_value.should == ""
      Field.new(:type=>Field::RADIO_BUTTON).default_value.should == ""
      Field.new(:type=>Field::SELECT_BOX).default_value.should == ""
    end

    it "should be nil for photo/audio upload boxes" do
      Field.new(:type=>Field::PHOTO_UPLOAD_BOX).default_value.should be_nil
      Field.new(:type=>Field::AUDIO_UPLOAD_BOX).default_value.should be_nil
    end

    it "should return empty list for checkboxes fields" do
      Field.new(:type=>Field::CHECK_BOXES).default_value.should == []
    end

    it "should raise an error if can't find a default value for this field type" do
      lambda {Field.new(:type=>"INVALID_FIELD_TYPE").default_value}.should raise_error
    end
  end

  describe "highlight information" do

    it "should initialize with empty highlight information" do
      field = Field.new(:name => "No highlight")
      field.is_highlighted?.should be_false
    end

    it "should set highlight information" do
      field = Field.new(:name => "highlighted")
      field.highlight_with_order 6
      field.is_highlighted?.should be_true
    end

    it "should unhighlight a field" do
      field = Field.new(:name => "new highlighted")
      field.highlight_with_order 1
      field.unhighlight
      field.is_highlighted?.should be_false
    end
  end

  describe "I18n" do

    it "should set the value of system language for the given field" do
      I18n.default_locale = "fr"
      field = Field.new(:name => "first name", :display_name => "first name in french",
                        :help_text => "help text in french",
                        :option_strings_text => "option string in french")
      field.display_name_fr.should == "first name in french"
      field.help_text_fr.should == "help text in french"
      field.option_strings_text_fr.should == "option string in french"
    end


    it "should get the value of system language for the given field" do
      I18n.locale = "fr"
      field = Field.new(:name => "first name", :display_name_fr => "first name in french", :display_name_en => "first name in english",
                        :help_text_en => "help text in english", :help_text_fr => "help text in french",
                        :option_strings_text_en => "option string in english", :option_strings_text_fr => "option string in french")
      field.display_name.should == field.display_name_fr
      field.help_text.should == field.help_text_fr
      field.option_strings_text.should == field.option_strings_text_fr
    end

    it "should fetch the default locale's value if translation is not available for given locale" do
      I18n.locale = "fr"
      field = Field.new(:name => "first name", :display_name_en => "first name in english",
                        :help_text_en => "help text in english", :help_text_fr => "help text in french",
                        :option_strings_text_en => "option string in english", :option_strings_text_fr => "option string in french")
      field.display_name.should == field.display_name_en
      field.help_text.should == field.help_text_fr
      field.option_strings_text.should == field.option_strings_text_fr
    end

  end
  describe "formatted hash" do

    it "should combine the field_name_translation into hash" do
      field = Field.new(:name => "first name", :display_name_en => "first name in english",
                        :help_text_en => "help text in english", :help_text_fr => "help text in french")
      field_hash = field.formatted_hash
      field_hash["display_name"].should == {"en" => "first name in english"}
      field_hash["help_text"].should == {"en" => "help text in english", "fr" => "help text in french"}
    end

    it "should return array for option_strings_text " do
      field = Field.new(:name => "f_name", :option_strings_text_en => "Yes\nNo")
      field_hash = field.formatted_hash
      field_hash["option_strings_text"] == {"en" => ["Yes", "No"]}
    end

  end

  describe "normalize line endings" do
    it "should convert \\r\\n to \\n" do
      field = Field.new :name => "test", :display_name_en => "test", :option_strings_text_en => "Uganda\r\nSudan"
      field.option_strings.should == [ "Uganda", "Sudan" ]
    end

    it "should use \\n as it is" do
      field = Field.new :name => "test", :display_name_en => "test", :option_strings_text_en => "Uganda\nSudan"
      field.option_strings.should == [ "Uganda", "Sudan" ]
    end

    it "should convert option_strings to option_strings_text" do
      field = Field.new :name => "test", :display_name_en => "test", :option_strings => "Uganda\nSudan"
      field.option_strings_text.should == "Uganda\nSudan"
    end

    it "should convert option_strings to option_strings_text" do
      field = Field.new :name => "test", :display_name_en => "test", :option_strings => ["Uganda", "Sudan"]
      field.option_strings_text.should == "Uganda\nSudan"
    end
  end

  it "should show that the field is new until the field is saved" do
     form = FormSection.create! :name => 'test_form', :unique_id => 'test_form'
     field = Field.new :name => "test_field", :display_name_en => "test_field", :type=>Field::TEXT_FIELD
     expect(field.new?).to be_true
     FormSection.add_field_to_formsection form, field
     expect(field.new?).to be_false
  end

   it "should show that the field is new after the field fails validation" do
     form =  FormSection.create! :name => 'test_form2', :unique_id => 'test_form'
     field = Field.new :name => "test_field2", :display_name_en => "test_field", :type=>Field::TEXT_FIELD
     FormSection.add_field_to_formsection form, field
     #Adding duplicate field.
     field = Field.new :name => "test_field2", :display_name_en => "test_field", :type=>Field::TEXT_FIELD
     FormSection.add_field_to_formsection form, field
     expect(field.errors.length).to be > 0
     field.errors[:name].should == ["Field already exists on this form"]
     expect(field.new?).to be_true
   end

  it "should fails save because fields are duplicated and fields remains as new" do
    #Try to create a FormSection with duplicate fields. That will make fails the save.
    fields = [Field.new(:name => "test_field2", :display_name_en => "test_field", :type=>Field::TEXT_FIELD),
              Field.new(:name => "test_field2", :display_name_en => "test_field", :type=>Field::TEXT_FIELD)]
    form = FormSection.create :name => 'test_form2', :unique_id => 'test_form', :fields => fields
    expect(fields.first.errors.length).to be > 0
    fields.first.errors[:name].should == ["Field already exists on this form"]
    expect(fields.last.errors.length).to be > 0
    fields.last.errors[:name].should == ["Field already exists on this form"]
    #Because it fails save, field remains new.
    expect(fields.first.new?).to be_true
    expect(fields.last.new?).to be_true
  end

  it "should fails save because fields changes make them duplicate" do
    #Create the FormSection with two valid fields.
    fields = [Field.new(:name => "test_field1", :display_name_en => "test_field1", :type=>Field::TEXT_FIELD),
              Field.new(:name => "test_field2", :display_name_en => "test_field2", :type=>Field::TEXT_FIELD)]
    form = FormSection.create :name => 'test_form2', :unique_id => 'test_form', :fields => fields
    expect(fields.first.errors.length).to be == 0
    expect(fields.first.new?).to be_false
    expect(fields.last.errors.length).to be == 0
    expect(fields.last.new?).to be_false

    #Update the first one to have the same name of the second,
    #This make fails saving the FormSection.
    fields.first.name = fields.last.name
    form.save
    expect(form.errors.length).to be > 0
    expect(fields.first.errors.length).to be > 0
    fields.first.errors[:name].should == ["Field already exists on this form"]

    #because field already came from the database should remains false
    expect(fields.first.new?).to be_false
    expect(fields.last.new?).to be_false

    #Fix the field and save again
    fields.first.name ="something_else"
    form.save
    expect(form.errors.length).to be == 0
  end

  # Test no longer valid. Now allowing sharing of fields

  # it "should fails save second form section because duplicate name in other form section" do
  #   field = Field.new(:name => "test_field1", :display_name_en => "test_field1", :type=>Field::TEXT_FIELD)
  #   form = FormSection.create :name => 'test_form1', :unique_id => 'test_form', :fields => [field]

  #   field = Field.new(:name => "test_field1", :display_name_en => "test_field1", :type=>Field::TEXT_FIELD)
  #   form = FormSection.create :name => 'test_form2', :unique_id => 'test_form', :fields => [field]
  #   field.errors[:name].should ==  ["Field already exists on form 'test_form1'"]
  # end
end
