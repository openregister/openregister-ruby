require_relative '../../lib/openregister'

RSpec.describe OpenRegister do

  def stub_tsv_request url, fixture, headers: {}
    stub_request(:get, url).
      to_return(status: 200,
        body: File.new(fixture),
        headers: { 'Content-Type': 'text/tab-separated-values;charset=UTF-8' }.merge(headers) )
  end

  before do
    allow(OpenRegister).to receive(:field).and_return double("OpenRegister::Field",
      register: '', datatype: 'string', cardinality: '1')

    allow(OpenRegister).to receive(:field).with('fields', anything).
      and_return double("OpenRegister::Field",
        register: '', datatype: 'string', cardinality: 'n')

    allow(OpenRegister).to receive(:field).with('food-premises-types', anything).
      and_return double("OpenRegister::Field",
        register: 'food-premises-type', datatype: 'string', cardinality: 'n')

    [
      'https://register.register.gov.uk/records.tsv',
      'https://register.alpha.openregister.org/records.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-records.tsv')
    end

    [
      'https://register.register.gov.uk/record/register.tsv',
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-register.tsv')
    end

    [
      'https://register.register.gov.uk/record/country.tsv',
      'https://register.alpha.openregister.org/record/country.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-country.tsv')
    end

    [
      'https://register.alpha.openregister.org/record/food-premises-rating.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-food-premises-rating.tsv')
    end

    [
      'https://register.alpha.openregister.org/record/company.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-company.tsv')
    end

    [
      'https://register.alpha.openregister.org/record/premises.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-premises.tsv')
    end

    [
      'https://register.alpha.openregister.org/record/food-premises.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/register-food-premises.tsv')
    end

    stub_tsv_request('https://register.alpha.openregister.org/record/food-premises-type.tsv',
      './spec/fixtures/tsv/register-food-premises-type.tsv')

    [
      'https://country.register.gov.uk/records.tsv',
      'https://country.alpha.openregister.org/records.tsv'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/country-records-1.tsv',
        headers: { 'Link': '<?page-index=2&page-size=100>; rel="next"' })
    end

    [
      'https://country.register.gov.uk/records.tsv?page-index=2&page-size=100',
      'https://country.alpha.openregister.org/records.tsv?page-index=2&page-size=100'
    ].each do |url|
      stub_tsv_request(url, './spec/fixtures/tsv/country-records-2.tsv',
        headers: { 'Link': '<?page-index=1&page-size=100>; rel="previous"' })
    end

    stub_tsv_request('https://food-premises-rating.alpha.openregister.org/records.tsv',
      './spec/fixtures/tsv/food-premises-rating-records.tsv')

    stub_tsv_request('https://field.alpha.openregister.org/record/food-premises.tsv',
      './spec/fixtures/tsv/food-premises.tsv')

    stub_tsv_request('https://food-premises.alpha.openregister.org/record/759332.tsv',
      './spec/fixtures/tsv/food-premises-759332.tsv')

    stub_tsv_request('https://company.alpha.openregister.org/record/07228130.tsv',
      './spec/fixtures/tsv/company-07228130.tsv')

    stub_tsv_request('https://premises.alpha.openregister.org/record/15662079000.tsv',
      './spec/fixtures/tsv/premises-15662079000.tsv')

    stub_tsv_request('https://food-premises-type.alpha.openregister.org/record/Restaurant.tsv',
      './spec/fixtures/tsv/food-premises-type-restaurant.tsv')

    stub_tsv_request('https://company.discovery.openregister.org/record/07007398/entries.tsv',
      './spec/fixtures/tsv/company-07007398-entries.tsv')

    stub_tsv_request('https://company.discovery.openregister.org/item/sha-256:cbe10411a9c0d760dee3a3f5aca27884702bdb806b60e15974953b1b62982297.tsv',
      './spec/fixtures/tsv/company-sha-256-cbe10411a9c0d760dee3a3f5aca27884702bdb806b60e15974953b1b62982297.tsv')

    stub_tsv_request('https://company.discovery.openregister.org/item/sha-256:d895d4d4a41c2b1b1ac07065174292790633e2eb7c4c20d7bf0b5f77798f03d3.tsv',
      './spec/fixtures/tsv/company-sha-256-d895d4d4a41c2b1b1ac07065174292790633e2eb7c4c20d7bf0b5f77798f03d3.tsv')

    stub_tsv_request('https://company.discovery.openregister.org/item/sha-256:6e21329956c6fa807e3a1a4fb5ce40a037917dfafbbeeeb45d2880745aef2850.tsv',
      './spec/fixtures/tsv/company-sha-256-6e21329956c6fa807e3a1a4fb5ce40a037917dfafbbeeeb45d2880745aef2850.tsv')
  end

  describe 'retrieve registers index' do
    it 'returns array of Ruby objects' do
      records = OpenRegister.registers
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with('https://register.register.gov.uk/records', :register, nil, nil, true, 100)
      OpenRegister.registers
    end

    it 'sets _uri method on register returning uri correctly' do
      uri = OpenRegister.registers[1]._uri
      expect(uri).to eq('https://country.register.gov.uk/')
    end

    let(:cache) { double() }

    context 'with cache passed in' do
      before { OpenRegister.cache = cache }
      after { OpenRegister.cache = nil }
      it 'calls correct url' do
        expect(OpenRegister).to receive(:retrieve).with('https://register.register.gov.uk/records', :register, nil, cache, true, 100)
        OpenRegister.registers
      end

      context 'with cache passed in and no value for key' do
        it 'returns array of Ruby objects' do
          expect(cache).to receive(:read).with('https://register.register.gov.uk/records.tsv').and_return nil
          expect(cache).to receive(:write).with('https://register.register.gov.uk/records.tsv', [
            File.read('./spec/fixtures/tsv/register-records.tsv'), nil
          ])
          OpenRegister.cache = cache
          records = OpenRegister.registers
          expect(records).to be_an(Array)
          records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
        end
      end

      context 'with cache passed in and value for key exists' do
        it 'returns array of Ruby objects' do
          expect(cache).to receive(:read).with('https://register.register.gov.uk/records.tsv').and_return([
            File.read('./spec/fixtures/tsv/register-records.tsv'), nil
          ])
          expect(cache).not_to receive(:write)
          OpenRegister.cache = cache
          records = OpenRegister.registers
          expect(records).to be_an(Array)
          records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
        end
      end
    end
  end

  describe 'retrieve registers index when passed base_url' do
    it 'returns array of Ruby objects with from_openregister set true' do
      records = OpenRegister.registers 'https://register.alpha.openregister.org/'
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
      records.each { |r| expect(r._base_url_or_phase).to eq('https://register.alpha.openregister.org/') }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with(
        'https://register.alpha.openregister.org/records', :register,
        'https://register.alpha.openregister.org/', nil, true, 100)
      OpenRegister.registers 'https://register.alpha.openregister.org/'
    end

    it 'sets _uri method on register returning uri correctly' do
      uri = OpenRegister.registers('https://register.alpha.openregister.org/')[1]._uri
      expect(uri).to eq('https://country.alpha.openregister.org/')
    end
  end

  describe 'retrieve registers index when passed phase' do
    it 'returns array of Ruby objects with from_openregister set true' do
      records = OpenRegister.registers :alpha
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an('OpenRegister::Register'.constantize) }
      records.each { |r| expect(r._base_url_or_phase).to eq(:alpha) }
    end

    it 'calls correct url' do
      expect(OpenRegister).to receive(:retrieve).with(
        'https://register.alpha.openregister.org/records', :register,
        :alpha, nil, true, 100)
      OpenRegister.registers :alpha
    end

    it 'sets _uri method on register returning uri correctly' do
      uri = OpenRegister.registers(:alpha)[1]._uri
      expect(uri).to eq('https://country.alpha.openregister.org/')
    end
  end

  shared_examples 'has attributes' do |hash|
    hash.each do |attribute, value|
      it { is_expected.to have_attributes(attribute => value) }
    end
  end

  describe 'retrieved record' do
    subject { OpenRegister.registers[1] }

    it 'has fields converted to array', focus: true do
      fields = subject.instance_variable_get('@fields')
      expect(fields).to eql(['country', 'name', 'official-name', 'citizen-names', 'start-date', 'end-date'])
    end

    include_examples 'has attributes', {
      entry_number: '3',
      fields: ['country', 'name', 'official-name', 'citizen-names', 'start-date', 'end-date'],
      phase: 'beta',
      register: 'country',
      registry: 'foreign-commonwealth-office',
      text: 'British English-language names and descriptive terms for countries'
    }
  end

  describe 'retrieve all a register\'s records handling pagination via #_all_records' do
    it 'returns records as Ruby objects' do
      records = OpenRegister.registers[1]._all_records
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an(OpenRegister::Country) }
      expect(records.size).to eq(2)
    end

    context 'when passed cache' do
      let(:cache) { double() }
      before { OpenRegister.cache = cache }
      after { OpenRegister.cache = nil }
      it 'returns records as Ruby objects and writes paginated tsv to cache' do
        expect(cache).to receive(:read).with('https://register.register.gov.uk/records.tsv').and_return nil
        expect(cache).to receive(:write).with('https://register.register.gov.uk/records.tsv', [
          File.read('./spec/fixtures/tsv/register-records.tsv'), nil
        ])
        expect(cache).to receive(:read).with('https://country.register.gov.uk/records.tsv').and_return nil
        expect(cache).to receive(:write).with('https://country.register.gov.uk/records.tsv', [
          File.read('./spec/fixtures/tsv/country-records-1.tsv'), '?page-index=2&page-size=100'
        ])
        expect(cache).to receive(:read).with('https://country.register.gov.uk/records.tsv?page-index=2&page-size=100').and_return nil
        expect(cache).to receive(:write).with('https://country.register.gov.uk/records.tsv?page-index=2&page-size=100', [
          File.read('./spec/fixtures/tsv/country-records-2.tsv'), nil
        ])

        records = OpenRegister.registers[1]._all_records
        expect(records).to be_an(Array)
        records.each { |r| expect(r).to be_an(OpenRegister::Country) }
        expect(records.size).to eq(2)
      end
    end
  end

  describe 'retrieve a register\'s records first page only via #_records' do
    it 'returns records as Ruby objects' do
      records = OpenRegister.registers[1]._records
      expect(records).to be_an(Array)
      records.each { |r| expect(r).to be_an(OpenRegister::Country) }
      expect(records.size).to eq(1)
    end
    context 'when passed cache' do
      let(:cache) { double() }
      before { OpenRegister.cache = cache }
      after { OpenRegister.cache = nil }
      it 'returns records as Ruby objects and writes paginated tsv to cache' do
        expect(cache).to receive(:read).with('https://register.register.gov.uk/records.tsv').and_return nil
        expect(cache).to receive(:write).with('https://register.register.gov.uk/records.tsv', [
          File.read('./spec/fixtures/tsv/register-records.tsv'), nil
        ])
        expect(cache).to receive(:read).with('https://country.register.gov.uk/records.tsv').and_return nil
        expect(cache).to receive(:write).with('https://country.register.gov.uk/records.tsv', [
          File.read('./spec/fixtures/tsv/country-records-1.tsv'), '?page-index=2&page-size=100'
        ])

        records = OpenRegister.registers[1]._records
        expect(records).to be_an(Array)
        records.each { |r| expect(r).to be_an(OpenRegister::Country) }
        expect(records.size).to eq(1)
      end
    end
  end

  describe 'retrieve a register\'s fields via #_fields' do
    it 'returns fields as Ruby objects' do
      register = OpenRegister.registers[1]
      fields = register._fields
      expect(fields).to be_an(Array)
      expect(fields.size).to eq(6)
      fields.each do |r|
        expect(r).to be_a(RSpec::Mocks::Double)
        expect(r.instance_variable_get(:@name)).to eq("OpenRegister::Field")
      end
    end
    context 'when passed cache' do
      let(:cache) { double() }
      before { OpenRegister.cache = cache }
      after { OpenRegister.cache = nil }
      it 'returns records as Ruby objects and writes paginated tsv to cache' do
        expect(cache).to receive(:read).with('https://register.register.gov.uk/records.tsv').and_return nil
        expect(cache).to receive(:write).with('https://register.register.gov.uk/records.tsv', [
          File.read('./spec/fixtures/tsv/register-records.tsv'), nil
        ])
        register = OpenRegister.registers[1]
        fields = register._fields
        expect(fields).to be_an(Array)
      end
    end
  end

  shared_examples 'has record attributes' do
    include_examples 'has attributes', {
      entry_number: '202',
      citizen_names: 'Gambian',
      country: 'GM',
      name: 'The Gambia',
      official_name: 'The Islamic Republic of The Gambia',
      entry_timestamp: '2016-04-05T13:23:05Z',
    }
  end

  describe 'retrieved register record' do
    subject { OpenRegister.registers[1]._all_records[0] }

    include_examples 'has record attributes'
  end

  describe 'retrieved register record when passed base_url' do
    subject { OpenRegister.registers('https://register.alpha.openregister.org/')[1]._all_records[0] }

    include_examples 'has record attributes'
    include_examples 'has attributes', { _base_url_or_phase: 'https://register.alpha.openregister.org/' }
  end

  describe 'retrieve register by name' do
    subject { OpenRegister.register('food-premises-rating', 'https://register.alpha.openregister.org/') }

    it 'returns register' do
      expect(subject.register).to eq('food-premises-rating')
    end

    it 'has _uri method returning uri correctly' do
      expect(subject._uri).to eq('https://food-premises-rating.alpha.openregister.org/')
    end
  end

  describe 'retrieve a record linked to from another record' do
    it 'returns linked record from another register' do
      expect(OpenRegister).to receive(:field).with('food-premises', :alpha).
        and_return double(register: 'food-premises', datatype: 'string', cardinality: '1')

      expect(OpenRegister).to receive(:field).with('business', :alpha).
        and_return double(register: 'company', datatype: 'curie', cardinality: '1')

      expect(OpenRegister).to receive(:field).with('premises', :alpha).
        and_return double(register: 'premises', datatype: 'string', cardinality: '1')

      register = OpenRegister.register('food-premises-rating', :alpha)
      record = register._records.first
      expect(record._food_premises._business.class.name).to eq('OpenRegister::Company')
      expect(record._food_premises._premises.class.name).to eq('OpenRegister::Premises')
      expect(record._food_premises.class.name).to eq('OpenRegister::FoodPremises')
    end
  end

  shared_examples 'has field attributes' do
    include_examples 'has attributes', {
      entry_number: '352',
      cardinality: '1',
      datatype: 'string',
      field: 'food-premises',
      phase: 'alpha',
      register: 'food-premises',
      text: 'A premises which serves or processes food.',
      start_date: nil,
      end_date: nil,
    }
  end

  describe 'retrieve specific entries from a given register' do
    let(:register) { 'company' }
    let(:record) { '07007398' }

    let(:entries) { OpenRegister.entries(register, record, :discovery) }

    it 'returns array of entries' do
      expect(entries).to be_a(Array)
      expect(entries.size).to eq 3
      entries.each do |entry|
        expect(entry).to be_a(OpenRegister::Entry)
      end
    end

    subject { entries.first }

    it "does not have _versions method on entry" do
      expect(subject.respond_to?(:_versions)).to be false
    end

    include_examples 'has attributes', {
      entry_number: "276",
      entry_timestamp: "2016-10-05T16:02:34Z",
      item_hash: "sha-256:cbe10411a9c0d760dee3a3f5aca27884702bdb806b60e15974953b1b62982297",
    }
  end

  describe 'retrieve specific item for a given item hash and register' do
    let(:register) { 'company' }
    let(:item_hash) { 'sha-256:cbe10411a9c0d760dee3a3f5aca27884702bdb806b60e15974953b1b62982297' }

    subject { OpenRegister.item(register, item_hash, :discovery) }

    it 'returns item as object' do
      expect(subject).to be_a(OpenRegister::Company)
    end

    include_examples 'has attributes', {
      company: "07007398",
      name: "GARSTON ENTERPRISE ACADEMY",
      company_status: "",
      industry: "85310",
      start_date: "2009-02-09",
      end_date: nil,
      item_hash: 'sha-256:cbe10411a9c0d760dee3a3f5aca27884702bdb806b60e15974953b1b62982297',
    }
  end

  describe 'retrieve specific record from a given register' do
    let(:register) { 'food-premises' }
    let(:record) { '759332' }

    subject { OpenRegister.record(register, record, 'https://register.alpha.openregister.org/') }

    include_examples 'has attributes', {
      business: "company:07228130",
      food_premises: "759332",
      local_authority: "506",
      name: "Byron",
      premises: "15662079000",
      end_date: nil,
      start_date: nil,
      food_premises_types: ["Restaurant"],
      item_hash: "sha-256:cdb325272d9f0d658616f9c36e3de595fc2b5ce51091696283cf2ca1d3d5741f",
    }

    it 'returns its uri' do
      expect(subject._uri).to eq('https://food-premises.alpha.openregister.org/record/759332')
    end

    it 'returns its curie' do
      expect(subject._curie).to eq('food-premises:759332')
    end

    it 'returns register from class method' do
      expect(subject.class.register).to eq('food-premises')
    end

    it 'returns linked record list from another register' do
      list = subject._food_premises_types
      expect(list).to be_a(Array)
      expect(list.first.class.name).to eq('OpenRegister::FoodPremisesType')
      expect(list.first.name).to eq('Restaurant')
    end

    it 'returns register object from class method' do
      register = subject.class._register(:alpha)
      expect(register.class.name).to eq('OpenRegister::Register')
      expect(register.register).to eq('food-premises')
    end

    it 'returns register object from instance method' do
      register = subject._register
      expect(register.class.name).to eq('OpenRegister::Register')
      expect(register.register).to eq('food-premises')
    end

    it 'returns register field objects from instance method' do
      fields = subject._register_fields
      expect(fields).to be_an(Array)
      expect(fields.size).to eq(8)
      fields.each do |r|
        expect(r).to be_a(RSpec::Mocks::Double)
        expect(r.instance_variable_get(:@name)).to eq("OpenRegister::Field")
      end
    end
  end

  describe 'retrieve versions of a record from a given register' do
    let(:register) { 'company' }
    let(:record) { '07007398' }

    let(:versions) { OpenRegister.versions(register, record, :discovery) }

    it 'returns array of objects' do
      expect(versions).to be_a(Array)
      expect(versions.size).to eq 3
      versions.each do |item|
        expect(item).to be_a(OpenRegister::Company)
      end
    end

    it 'has highest entry number last' do
      expect(versions.first.entry_number < versions.last.entry_number).to be true
    end

    describe 'returned version' do
      subject { versions.first }

      include_examples 'has attributes', {
        company: "07007398",
        name: "GARSTON ENTERPRISE ACADEMY",
        company_status: "",
        industry: "85310",
        start_date: "2009-02-09",
        end_date: nil,
        item_hash: 'sha-256:cbe10411a9c0d760dee3a3f5aca27884702bdb806b60e15974953b1b62982297',
        entry_timestamp: '2016-10-05T16:02:34Z',
        entry_number: '276',
      }
    end

    describe 'retrieve versions of record from record object' do
      let(:_versions) do
        record = versions.first
        record._versions
      end

      it 'returns array of objects' do
        expect(_versions).to be_a(Array)
        expect(_versions.size).to eq 3
        _versions.each do |item|
          expect(item).to be_a(OpenRegister::Company)
        end
      end

      it 'has own record version as itself' do
        expect(versions.first).to eq _versions.first
      end

      describe 'returned version' do
        subject { _versions.first }

        include_examples 'has attributes', {
          company: "07007398",
          name: "GARSTON ENTERPRISE ACADEMY",
          company_status: "",
          industry: "85310",
          start_date: "2009-02-09",
          end_date: nil,
          item_hash: 'sha-256:cbe10411a9c0d760dee3a3f5aca27884702bdb806b60e15974953b1b62982297',
          entry_timestamp: '2016-10-05T16:02:34Z',
          entry_number: '276',
        }
      end

      describe 'retrieve version changes' do
        it "is array of array of differences" do
          entry = versions.first
          changes = entry._version_changes
          expect(changes.size).to eq 3
          expect(changes[0]).to eq({
            "name" => "GARSTON ENTERPRISE ACADEMY",
            "name-change-date" => nil,
            "entry-number" => "276",
            "entry-timestamp" => "2016-10-05T16:02:34Z"
          })
          expect(changes[1]).to eq({
            "name" => "ENTERPRISE SOUTH LIVERPOOL ACADEMY",
            "name-change-date" => "2009-12-21",
            "entry-number" => "277",
            "entry-timestamp" => "2016-10-06T17:02:34Z"
          })
          expect(changes[2]).to eq({
            "name" => "THE LIVERPOOL JOINT CATHOLIC AND CHURCH OF ENGLAND ACADEMIES TRUST",
            "name-change-date" => "2015-03-08",
            "entry-number" => "278",
            "entry-timestamp" => "2016-10-07T18:02:34Z"
          })
        end
      end

      describe 'display version changes' do
        it "shows value changed with date range" do
          entry = versions.first
          display = entry._version_change_display(:name, :start_date, :name_change_date)
          expect(display.size).to eq 2
          expect(display[0]).to eq "ENTERPRISE SOUTH LIVERPOOL ACADEMY 2009-12-21 - 2015-03-08"
          expect(display[1]).to eq "GARSTON ENTERPRISE ACADEMY 2009-02-09 - 2009-12-21"
        end
      end
    end
  end

end
