require 'spec_helper'
require 'yaml'

secrets = YAML.load_file('./secrets.yml')

describe Vaporizer::Strain do

  it { expect(Vaporizer::Strain).to respond_to(:strains_search) }
  it { expect(Vaporizer::Strain).to respond_to(:strains_show) }
  it { expect(Vaporizer::Strain).to respond_to(:strains_reviews_index) }
  it { expect(Vaporizer::Strain).to respond_to(:strains_reviews_show) }
  it { expect(Vaporizer::Strain).to respond_to(:strains_photos_index) }
  it { expect(Vaporizer::Strain).to respond_to(:strains_availabilities_index) }

  before :all do
    Vaporizer.configure do |config|
      config.app_id = secrets['app_id']
      config.app_key = secrets['app_key']
    end

    @strain_slug = 'la-confidential'
    @non_existing_strain_slug = "5d0e71bda1005d0770a4e31e1a27580d"

    VCR.use_cassette('strains/non-existing-details') do
      begin
        Vaporizer::Strain.details(@non_existing_strain_slug)
      rescue Vaporizer::NotFound
      end
    end

    VCR.use_cassette('strains/non-existing-reviews') do
      begin
        Vaporizer::Strain.reviews(@non_existing_strain_slug, page: 0, take: 1)
      rescue Vaporizer::NotFound
      end
    end
  end

  describe '.search(params = {})' do
    context "valid params" do
      before :all do
        @take = 10
        VCR.use_cassette('strains/search-valid_params') do
          @strains = Vaporizer::Strain.search(search: '', page: 0, take: @take)
        end
      end

      it 'should return a hash' do
        VCR.use_cassette('strains/search-valid_params') do
          expect(@strains.class).to be(Hash)
        end
      end

      it "should return a hash with a key named 'Strains'" do
         VCR.use_cassette('strains/search-valid_params') do
          expect(@strains).to have_key('Strains')
        end
      end

      it "should return the right number of strains" do
        VCR.use_cassette('strains/search-valid_params') do
          expect(@strains['Strains'].size).to eq(@take)
        end
      end
    end

    context "missing params" do
      it "should raise error Vaporizer::MissingParameter" do
        expect { Vaporizer::Strain.search(search: '', page: 0) }.to raise_error(Vaporizer::MissingParameter)
      end

      it "should raise error Vaporizer::MissingParameter" do
        expect { Vaporizer::Strain.search(search: '', take: 0) }.to raise_error(Vaporizer::MissingParameter)
      end
    end

    context "a bit more complex search" do
      before :all do
        @flavor = 'blueberry'
        @condition = 'anxiety'
        VCR.use_cassette('strains/search-complex') do
          @strains = Vaporizer::Strain.search(
            filters: {
              flavors: [@flavor],
              conditions: [@condition]
            },
            search: '',
            page: 0, take: 1
          )
        end
      end

      it 'should return a hash' do
        VCR.use_cassette('strains/search-complex') do
          expect(@strains.class).to be(Hash)
        end
      end

      it "should return a hash with a key named 'Strains'" do
        VCR.use_cassette('strains/search-complex') do
          expect(@strains).to have_key('Strains')
        end
      end

      it "should return strains with specified flavor" do
        VCR.use_cassette('strains/search-complex') do
          expect(
            @strains["Strains"][0]['Flavors'].map { |flavor| flavor['Name'].downcase }
          ).to include(@flavor)
        end
      end

      it "should return strains with specified condition" do
        VCR.use_cassette('strains/search-complex') do
          expect(
            @strains["Strains"][0]['Conditions'].map { |condition| condition['Name'].downcase }
          ).to include(@condition)
        end
      end
    end
  end

  describe '.details(slug)' do
    before :all do
      VCR.use_cassette('strains/details') do
        @strain = Vaporizer::Strain.details(@strain_slug)
      end
    end

    it 'should return a hash' do
      VCR.use_cassette('strains/details') do
        expect(@strain.class).to be(Hash)
      end
    end

    it "should return the specified strain" do
      VCR.use_cassette('strains/details') do
        expect(@strain['slug']).to eq(@strain_slug)
      end
    end

    it "should raise an error if strain doesn't exist" do
      expect do
        VCR.use_cassette('strains/non-existing-details') do
          Vaporizer::Strain.details(@non_existing_strain_slug)
        end
      end.to raise_error(Vaporizer::NotFound)
    end
  end

  describe '.reviews(slug, params = {})' do
    context "valid params" do
      before :all do
        @take = 7
        @page = 0
        VCR.use_cassette('strains/reviews') do
          @reviews = Vaporizer::Strain.reviews(@strain_slug, { page: @page, take: @take })
        end
      end

      it 'should return a hash' do
        VCR.use_cassette('strains/reviews') do
          expect(@reviews.class).to be(Hash)
        end
      end

      it "should return a hash with a key named 'reviews'" do
         VCR.use_cassette('strains/reviews') do
          expect(@reviews).to have_key('reviews')
        end
      end

      it "should return the right number of reviews" do
        VCR.use_cassette('strains/reviews') do
          expect(@reviews['reviews'].size).to eq(@take)
        end
      end

      it "should give paging context corresponding to sent params" do
        VCR.use_cassette('strains/reviews') do
          expect(@reviews['pagingContext']['PageIndex']).to eq(@page)
        end
      end

      it "should give paging context corresponding to sent params" do
        VCR.use_cassette('strains/reviews') do
          expect(@reviews['pagingContext']['PageSize']).to eq(@take)
        end
      end

      it "should raise an error if strain doesn't exist" do
        expect do
          VCR.use_cassette('strains/non-existing-reviews') do
            Vaporizer::Strain.reviews(@non_existing_strain_slug, { page: 0, take: 1 })
          end
        end.to raise_error(Vaporizer::NotFound)
      end
    end

    context "missing params" do
      it "should raise error Vaporizer::MissingParameter" do
        expect { Vaporizer::Strain.reviews(@strain_slug, { take: 2 }) }.to raise_error(Vaporizer::MissingParameter)
      end

      it "should raise error Vaporizer::MissingParameter" do
        expect { Vaporizer::Strain.reviews(@strain_slug, { page: 1 }) }.to raise_error(Vaporizer::MissingParameter)
      end
    end
  end

  describe '.review_details(slug, review_id)' do
    context "valid params" do
      before :all do
        @id = 2836
        @strain_slug = @strain_slug
        VCR.use_cassette('strains/review_details') do
          @review = Vaporizer::Strain.review_details(@strain_slug, @id)
        end
      end

      it 'should return a hash' do
        VCR.use_cassette('strains/review_details') do
          expect(@review.class).to be(Hash)
        end
      end

      it 'should return the right review' do
        VCR.use_cassette('strains/review_details') do
          expect(@review['id']).to eq(@id)
        end
      end

      it 'should correspond to the right strain' do
        VCR.use_cassette('strains/review_details') do
          expect(@review['strainSlug']).to eq(@strain_slug)
        end
      end
    end
  end

  describe '.photos(slug, params = {})' do
    context "valid params" do
      before :all do
        @take = 7
        @page = 0
        VCR.use_cassette('strains/photos') do
          @photos = Vaporizer::Strain.photos(@strain_slug, { page: @page, take: @take })
        end
      end

      it 'should return a hash' do
        VCR.use_cassette('strains/photos') do
          expect(@photos.class).to be(Hash)
        end
      end

      it "should return a hash with a key named 'photos'" do
         VCR.use_cassette('strains/photos') do
          expect(@photos).to have_key('photos')
        end
      end

      it "should return the right number of reviews" do
        VCR.use_cassette('strains/photos') do
          expect(@photos['photos'].size).to eq(@take)
        end
      end

      it "should give paging context corresponding to sent params" do
        VCR.use_cassette('strains/photos') do
          expect(@photos['pagingContext']['PageIndex']).to eq(@page)
        end
      end

      it "should give paging context corresponding to sent params" do
        VCR.use_cassette('strains/photos') do
          expect(@photos['pagingContext']['PageSize']).to eq(@take)
        end
      end

      context "missing params" do
        it "should raise error Vaporizer::MissingParameter" do
          expect { Vaporizer::Strain.photos(@strain_slug, { take: 2 }) }.to raise_error(Vaporizer::MissingParameter)
        end

        it "should raise error Vaporizer::MissingParameter" do
          expect { Vaporizer::Strain.photos(@strain_slug, { page: 1 }) }.to raise_error(Vaporizer::MissingParameter)
        end
      end

      it "should raise an error if strain doesn't exist" do
        expect do
          VCR.use_cassette('strains/non-existing-photos') do
            Vaporizer::Strain.photos(@non_existing_strain_slug, { page: 0, take: 1 })
          end
        end.to raise_error(Vaporizer::NotFound)
      end
    end
  end

  describe '.availabilities(slug, params = {})' do
    context "valid params" do
      before :all do
        @take = 7
        @page = 0
        VCR.use_cassette('strains/availabilities') do
          @availabilities = Vaporizer::Strain.availabilities(@strain_slug, { lat: 50, lon: 50 })
        end
      end

      it 'should return an array' do
        VCR.use_cassette('strains/availabilities') do
          expect(@availabilities.class).to be(Array)
        end
      end

      context "missing params" do
        it "should raise error Vaporizer::MissingParameter" do
          expect { Vaporizer::Strain.availabilities(@strain_slug, { lat: 0 }) }.to raise_error(Vaporizer::MissingParameter)
        end

        it "should raise error Vaporizer::MissingParameter" do
          expect { Vaporizer::Strain.availabilities(@strain_slug, { lon: 0 }) }.to raise_error(Vaporizer::MissingParameter)
        end
      end

      it "should raise error if strain doesn't exist" do
        expect do
          VCR.use_cassette('strains/non-existing-availabilities') do
            Vaporizer::Strain.availabilities(@non_existing_strain_slug, { lat: 0, lon: 0 })
          end
        end.to raise_error(Vaporizer::NotFound)
      end
    end
  end
end
