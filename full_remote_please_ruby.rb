#!/bin/ruby
require 'mechanize'
require 'kconv'
 
STDOUT.sync = true # 標準出力のバッファリングを無効にし、即座にフラッシュする。
puts '到着駅を入力してください。'
ARRIVAL_STATION = gets.chomp

class SearchForm

  def initialize(departure:, destination:, train_type:)
    @train_type = train_type
    train_type_index = case train_type
                          when 'express' then 0
                          when 'local' then 2
                          else puts 'invalid value, displaying express' '0'
                          end

    agent = Mechanize.new
    page = agent.get('https://###')
    form = page.form_with(name: 'fm_nori')
    form['###'] = departure
    form['###'] = destination
    form['###'] = '8' # 時
    form['###'] = '4' # 分 1桁目
    form['###'] = '5' # 分 2桁目
    form.radiobutton_with(name:'Cway' ,value: '1').check
    form['###'] = train_type_index
    submit_button = form.button_with(value: '検索')
    express_result_page = form.submit(submit_button)

    # Kconv;　文字コード変換のRubyのデフォルトライブラリ
    # この行無しでは文字化けしてしまう。
    response_body = Kconv.kconv(express_result_page.body, Kconv::UTF8, Kconv::UTF8)
    # String -> HTML(Nokogiri)
    response_body = Nokogiri::HTML(response_body)

    @trains = response_body.css('###').map(&:text)
    @railways = response_body.css('###').map{ |element| element.text.strip }
    @departure_and_arrival_time =  response_body.css('###').text
    @travel_time = response_body.css('###').text.sub('所要時間','') #所要時間
  end
  
  def display
    railways_added_pipe = @railways.map { |railway| ' | ' + railway }
    # zip → 二つの配列を組み合わせ、ペアの二次元配列を生成
    # flatten →　１次元配列
    # compact → nil を除外
    stations_and_railways = @trains.zip(railways_added_pipe).flatten.compact
    
    case @train_type
      when 'local' then puts '【各駅】' 
      when 'express' then puts '【急行】'
    end
    puts @departure_and_arrival_time
    puts @travel_time
    puts ''
    # 駅名・路線を出力
    stations_and_railways.each_with_index do |content, i|
      puts content
      puts ' |' if i < stations_and_railways.size - 1
    end
    puts ''
  end
end

  local_train = SearchForm.new(departure:'町田', destination:ARRIVAL_STATION, train_type:'local')
  express_train = SearchForm.new(departure:'町田', destination:ARRIVAL_STATION, train_type:'express')

  local_train.display
  express_train.display
