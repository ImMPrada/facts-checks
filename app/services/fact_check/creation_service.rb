class FactCheck::CreationService
  attr_reader :fact_check

  def initialize(params)
    self.params = params
    self.fact_check = nil
  end

  def build
    self.fact_check = FactCheck.new(
      source_url: params[:source_url],
      title: params[:title],
      reasoning: params[:reasoning],
      veredict: find_or_create_veredict,
      publication_date: find_or_create_publication_date
    )
  end

  def save!
    fact_check.save!
    fact_check
  end

  private

  attr_accessor :params
  attr_writer :fact_check

  def find_or_create_veredict
    veredict_param = params[:veredict]
    return nil if veredict_param.nil?
    return veredict_param if veredict_param.is_a?(Veredict)

    Veredict.find_or_create_by!(name: veredict_param.upcase)
  end

  def find_or_create_publication_date
    date_param = params[:publication_date]
    return nil if date_param.nil?
    return date_param if date_param.is_a?(PublicationDate)

    PublicationDate.find_or_create_by!(date: date_param)
  end
end
