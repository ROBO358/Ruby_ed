require 'optparse'

# 適当なタイミングでバージョン更新を行う
# メジャーバージョン.マイナーバージョン.パッチバージョン
# メジャーバージョン: 互換性のない変更(APIの変更など)
# マイナーバージョン: 互換性のある新機能の追加(新しい機能の追加)
# パッチバージョン: 互換性のあるバグ修正
Version = '0.5.0'

# 実装済みのコマンド
# コマンド名 => メソッド名(_コマンド名)
Command = ['a', 'c', 'd', 'f', 'i', 'j', 'n', 'p', 'q', 'w', 'wq', '=']

class ED
    # クラス呼び出し時
    def initialize
        # 変数初期化
        @buffer = []
        @current_line = 0 # zero-based
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
            begin
                @file_name = ARGF.filename
                @buffer = ARGF.readlines
                @current_line = @buffer.length - 1 # zero-based
            rescue Errno::ENOENT => e
                puts e.message
                exit
            end
        end

        loop {
            # コマンドを読み込み、実行する
            _eval(_read())

            # 実行中に配列表現等で複数回printする必要があるため、ここで呼び出すことはしない。
            # _print()
        }
    end

    ##############################REP###########################

    # Read
    private def _read
        # promptを表示
        print @prompt

        # 入力を受け付ける
        return $stdin.gets
    end

    # Eval
    private def _eval(input)
        # 名前付きキャプチャのローカル変数への代入は式展開が存在すると仕様上行えないため、式展開を使用しない
        # addr = '(?:\d+|[.$,;]|\/.*\/)'
        # cmnd = '(?:wq|[acdfgijnpqrw=]|\z)'
        # prmt = '(?:.*)'
        # /\A(?:(?<addr_from>#{addr})(?:,(?<addr_to>#{addr}))?)?(?<cmnd>#{cmnd})(?<prmt>#{prmt})?\n\z/ =~ input

        # 名前付きキャプチャを使用し、各変数にデータを抽出する。
        /\A(?:(?<addr_from>\d+|[.$,;]|\/.*\/)(?:,(?<addr_to>\d+|[.$,;]|\/.*\/))?)?(?<cmnd>wq|[acdfgijnpqrw=]|\z)?(?<prmt>.*)?\n\z/ =~ input

        # コマンドを実行する

        # Debug用解析結果
        p addr_from
        p addr_to
        p cmnd
        p prmt

        # コマンドが指定されていない場合
        if cmnd == ' ' || cmnd == '' || cmnd == nil
            # 空行の場合、現在行を更新する
            update_current_line(addr_from, addr_to)

        # 存在しないコマンドを呼び出さないように(インジェクションされそうなので)
        elsif Command.include?(cmnd)
            # コマンドの実行
            self.send("_#{cmnd}", addr_from, addr_to, prmt)

        # 定義されていない場合
        else
            # 未定義のコマンド
            _error()
        end

    end

    # Print
    private def _print(str)
        print str if !(str.nil? || str.empty?)
    end

    # Error
    private def _error(err = nil)
        _print("?\n")
        _print(err.to_s + "\n") if !(err.nil? || err.empty?)
    end

    #####################各コマンドの実装########################

    # 後挿入
    private def _a(addr_from, addr_to, prmt)
        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err && to_idx != -1
            _error()
            return
        end

        # カレント行は入力する一つ前の行とする
        @current_line = to_idx.to_i # zero-based

        loop{
            # 後挿入なので次の行に移動する
            to_idx += 1

            # 入力を受け付ける
            input = $stdin.gets

            # 入力を終了する場合
            break if input == ".\n"

            # 入力を挿入
            @buffer.insert(to_idx, input)

            # 現在行を更新
            @current_line += 1
        }
    end

    # 前挿入
    private def _i(addr_from, addr_to, prmt)
        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err
            _error()
            return
        end

        # カレント行は入力する一つ前の行とする
        @current_line = to_idx.to_i # zero-based

        loop{
            ## 前挿入なので一つ前の行にする
            # 人間は1行目が1行目であると思っているので、予め人間に寄り添う
            # to_idx += 1

            # 入力を受け付ける
            input = $stdin.gets

            # 入力を終了する場合
            break if input == ".\n"

            # 入力を挿入
            @buffer.insert(to_idx, input)

            # 現在行を更新
            @current_line += 1
        }

    end

    # 変更
    private def _c(addr_from, addr_to, prmt)
        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err
            _error()
            return
        end

        # `from_idx`から`to_idx`までの要素を削除
        @buffer.slice!(from_idx..to_idx)

        _a((from_idx).to_s, (from_idx).to_s, prmt)
    end

    # 行削除
    # `@buffer`の内容を削除する
    private def _d(addr_from, addr_to, prompt)
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

    # デフォルトのファイル名を変更する
    private def _f(addr_from, addr_to, prompt)
        # promptの有無確認
        if prompt.nil? || prompt.empty?
            # ファイル名を表示
            _print(@file_name.to_s + "\n")
        else
            # 前後の空白等を削除
            prompt.strip!

            # ファイル名を更新
            @file_name = prompt
        end
    end

    # 行の結合
    private def _j(addr_from, addr_to, prompt)
        # アドレスが指定されてなければ、現在行を対象とする
        if (addr_from.nil? || addr_from.empty?) && (addr_to.nil? || addr_to.empty?)
            addr_from = addr_to = '.' # 現在行
        end

        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err
            _error()
            return
        end

        # 指定された行が連続していなければ、次行と結合する
        if from_idx == to_idx
            to_idx += 1
        end

        # 結合する行を取得
        lines = @buffer[from_idx..to_idx]

        # 結合する行の末尾から改行を削除
        lines.each_with_index {|line, idx|
            line.chomp!("") if idx != lines.length - 1
        }

        # 結合する行を削除
        @buffer.slice!(from_idx..to_idx)

        # 結合する行を結合
        @buffer.insert(from_idx, lines.join)

        # 現在行を更新
        @current_line = from_idx
    end

    # 行番号ありで出力
    private def _n(addr_from, addr_to, prompt)
        print_buffer(addr_from, addr_to, true)
    end

    # 行番号なしで出力
    private def _p(addr_from, addr_to, prompt)
        print_buffer(addr_from, addr_to)
    end

    # 終了
    private def _q(addr_from, addr_to, prompt)
        # アドレスがどちらかにも指定されていない場合は終了する
        if (addr_from.nil? || addr_from.empty?) && (addr_to.nil? || addr_to.empty?)
            exit(0)
        else
            _error
        end
    end

    # 保存
    private def _w(addr_from, addr_to, prompt)
        # アドレスが指定されてなければ、すべての行を対象とする
        if (addr_from.nil? || addr_from.empty?) && (addr_to.nil? || addr_to.empty?)
            addr_from = '1' # 1行目
            addr_to = '$' # 最終行
        end

        # アドレスの検証
        _err, from_idx, to_idx = address_verification(addr_from, addr_to)
        if _err
            _error()
            return
        end

        # ファイル名が指定されていない場合は、デフォルトのファイル名を使用する
        if prompt.nil? || prompt.empty?
            prompt = @file_name
        end

        # ファイル名を取得
        file_name = prompt.strip

        # ファイルを開く
        file = File.open(file_name, "w")

        # 書き込む文字数
        write_size = 0

        # ファイルに書き込む
        @buffer[from_idx..to_idx].each {|line|
            file.write(line)
            write_size += line.length
        }

        # ファイルを閉じる
        file.close

        # 書き込んだ文字数を表示
        _print("#{write_size} characters written\n")
    end

    #############################その他##########################

    # アドレスの有効性を検証
    # 戻り値はZero-based
    private def address_verification(addr_from, addr_to)
        # 初期値(値には全範囲を指定)
        from_idx = 0
        to_idx = @buffer.length - 1
        _err = false

        # アドレスが`.`と指定されている場合は現在の行を指定
        # 人間は1から数えているため、人間のフリをしている
        addr_from = (@current_line.to_i+1).to_s if addr_from == '.'
        addr_to = (@current_line.to_i+1).to_s if addr_to == '.'

        # アドレスが`$`と指定されている場合は最終行を指定
        # 人間は1から数えているため、人間のフリをしている
        addr_from = (@buffer.length.to_i).to_s if addr_from == '$'
        addr_to = (@buffer.length.to_i).to_s if addr_to == '$'

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
    private def print_buffer(addr_from, addr_to, number_flg = false)
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

    # カレント行を更新する
    private def update_current_line(addr_from, addr_to)
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
