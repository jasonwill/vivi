require 'spec_helper'

describe "docs" do
  before do
    @doc = Mimi::Doc.create!(:title => "some terrific title", :asset => File.new(Rails.root + 'public/media/test.jpg'))
  end

  it "show all in wall" do
    visit docs_path
    page.should have_content("xxxx")
    #should render_template("layouts/application")
   
  end

  it "single doc view" do
    visit doc_path(@doc.id)
    within("#doc h2") do
      page.should have_content("doc title")
    end
  end
end