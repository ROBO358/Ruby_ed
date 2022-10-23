require 'optparse'

Version = '0.0.2'

class ED
    def initialize
        # 変数初期化
        @buffer = []
        @current_line = @buffer.length - 1
        @file_name = nil
        @quit = false
        @prompt = ''

        # OptionParserのインスタンスを作成
        @opt = OptionParser.new

        # 各オプション(.parse!時実行)
        @opt.on('-p', '--prompt=VAL') {|v| @prompt = v}

        # オプションを切り取る
        @opt.parse!(ARGV)

        # ファイルが指定されていた場合、ファイルを開く
        if ARGV.length > 0
            @file_name = ARGF.filename
            @buffer = ARGF.readlines
            @current_line = @buffer.length - 1
        end

        # 入力を受け付ける
        _read
    end

    def _read
        # promptを表示
        print @prompt

        # 入力を受け付ける
        input = $stdin.gets

        # 入力を評価する
        _eval(input)
    end

    def _eval(input)
        # 名前付きキャプチャのローカル変数への代入は式展開が存在すると仕様上行えないため、式展開を使用しない
        # addr = '(?:\d+|[.$,;]|\/.*\/)'
        # cmnd = '(?:wq|[acdgijnpqrw=]|\z)'
        # prmt = '(?:.*)'
        # /\A(?:(?<addr_from>#{addr})(?:,(?<addr_to>#{addr}))?)?(?<cmnd>#{cmnd})(?<prmt>#{prmt})?\n\z/ =~ input

        # 名前付きキャプチャを使用し、各変数にデータを抽出する。
        /\A(?:(?<addr_from>\d+|[.$,;]|\/.*\/)(?:,(?<addr_to>\d+|[.$,;]|\/.*\/))?)?(?<cmnd>wq|[acdgijnpqrw=]|\z)?(?<prmt>.*)?\n\z/ =~ input

        # コマンドを実行する

        # Debug用解析結果
        p addr_from
        p addr_to
        p cmnd
        p prmt

        case cmnd
            when 'a'
            when 'c'

            # 行削除
            when 'd'
                delete_buffer(addr_from, addr_to)

            when 'f'
            when 'i'
            when 'j'

            # 行番号ありで出力
            when 'n'
                print_buffer(addr_from, addr_to, true)

            # 出力
            when 'p'
                print_buffer(addr_from, addr_to)

            when 'q'
                # アドレスがどちらかにも指定されていない場合は終了する
                if (addr_from.nil? || addr_from.empty?) && (addr_to.nil? || addr_to.empty?)
                    return
                else
                    _error
                end

            when 'w'
            when 'wq'
            when '='

            when '', ' ', nil
                update_current_line(addr_from, addr_to)

            else
                _error()

            end

        # 読み込みを続ける
        _read
    end

    def _print(str)
        print str if !(str.nil? || str.empty?)
    end

    def _error
        _print("?\n")
    end

    # アドレスの有効性を検証
    def address_verification(addr_from, addr_to)
        # 初期値(値には全範囲を指定)
        from_idx = 0
        to_idx = @buffer.length - 1
        _err = false

        # アドレスが`.`と指定されている場合は現在の行を指定
        # 人間は1から数えているため、人間のフリをしている
        addr_from = (@current_line.to_i+1).to_s if addr_from == '.'
        addr_to = (@current_line.to_i+1).to_s if addr_to == '.'

        # どちらもアドレス指定がなければエラー
        if (addr_from.nil? || addr_from.empty?) && (addr_to.nil? || addr_to.empty?)
            _err = true

        # `addr_from`のみ指定がなければ`addr_to`のアドレスのみを出力
        elsif addr_from.nil? || addr_from.empty?
            # アドレスが範囲外の場合はエラー
            if addr_to.to_i - 1 < 0 || addr_to.to_i > @buffer.length
                _err = true
            end
            from_idx = to_idx = addr_to.to_i - 1

        # `addr_to`のみ指定がなければ`addr_from`のアドレスのみを出力
        elsif addr_to.nil? || addr_to.empty?
            # アドレスが範囲外の場合はエラー
            if addr_from.to_i - 1 < 0 || addr_from.to_i > @buffer.length
                _err = true
            end
            from_idx = to_idx = addr_from.to_i - 1

        # どちらも指定されていれば、`addr_from`から`addr_to`までを出力
        else
            # アドレスが範囲外もしくは、`addr_from`が`addr_to`より大きい場合はエラー
            if addr_to.to_i < addr_from.to_i || addr_from.to_i - 1 < 0 || @buffer.length < addr_to.to_i
                _err = true
            end
            from_idx = addr_from.to_i - 1
            to_idx = addr_to.to_i - 1
        end

        # エラーか否か, 出力する範囲のインデックス
        return _err, from_idx, to_idx
    end

    # `@buffer`の内容を出力する
    def print_buffer(addr_from, addr_to, number_flg = false)
        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err
            _error()
            return
        end

        @buffer.each_with_index do |line, index|
            if index >= from_idx && index <= to_idx
                _print("#{index + 1}    ") if number_flg
                _print("#{line}")
            end
        end

        # 現在の行を更新
        @current_line = to_idx
    end

    # `@buffer`の内容を削除する
    def delete_buffer(addr_from, addr_to)
        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err
            _error()
            return
        end

        # `from_idx`から`to_idx`までの要素を削除
        @buffer.slice!(from_idx..to_idx)

        # 現在の行を更新
        @current_line = @buffer.length - (to_idx - from_idx) - 1
    end

    # カレント行を更新する
    def update_current_line(addr_from, addr_to)
        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err
            _error()
            return
        end

        # 現在の行を更新
        @current_line = to_idx
    end

end

ED.new
