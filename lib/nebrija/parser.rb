require 'nokogiri'

class Parser
  
  META_REGEX = /^([a-zA-Z]{1,4}+\.[ ]{1,2})+/

  def initialize(rae_data, word)
    @doc = Nokogiri::HTML(rae_data
                      .gsub(/[\n]+/, '')
                      .gsub(/[ ]{2,}+/, ' '))
    @word = word
  end

  def parse

    return {:error => 'Word does not exist. Sorry.'} if !valid? 

    if single?
      parse_single
    else
      parse_multiple
    end
  end

  def single?
    @doc.css('body > ul').length.zero?
  end

  private 
  def parse_single
    data = []
    result = {:id => @doc.css('body > div > a').first['name'].to_i, :data => data}
    state = :entry # TODO. Improve FSM syntax.
    index = -1 # HACK(javierhonduco)

    @doc.css('body > div > p').each do |entry|
      if entry['class'] == 'p' and state == :entry
        word = entry.css('span').inner_text
        word = '=>' if word == ''
        data << {
          :word => word.gsub(/~/, @word).strip.capitalize, 
          :meanings => []
        }
        index+=1
      else
        text = entry.inner_text.strip.gsub(/[0-9]+\.[ ]/, '')
        next if text[0] == '(' # Del latín, Nil.    
        unparsed_meta = text.scan META_REGEX
        text = text.gsub(META_REGEX, '')
        data[index][:meanings] << {
          :word => text, 
          :meta => (unparsed_meta.join.strip if unparsed_meta.join.strip != ''),
        } if !text.nil? and text != ''
        state = :definitions
      end
      state = :entry
    end 
    result
  end

  def parse_multiple
    multiple_result = []
    @doc.css('body > ul > li > a').each do |word|
      multiple_result << {
        :word => word.css('span').first.inner_text,
        :href => word['href'].gsub(/search\?id=/, '')
      }
    end 
    multiple_result
  end

  def valid?
    (@doc.css('title').inner_text =~/error/).nil?
  end
end