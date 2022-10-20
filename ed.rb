require 'optparse'

Version = '0.0.1'

class ED
    def initialize
        # 変数初期化
        @buffer = []
        @line = 0
        @file = nil
        @quit = false
        @prompt = ''

        # OptionParserのインスタンスを作成
        @opt = OptionParser.new

        # 各オプション(.parse!時実行)
        @opt.on('-p', '--prompt=VAL') {|v| @prompt = v}

        # オプションを切り取る
        @opt.parse!(ARGV)

        # ファイルが指定されていた場合、ファイルを開く
        @buffer = ARGF.readlines if ARGV.length > 0

        # 入力を受け付ける
        _read
    end

    def _read
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
        /\A(?:(?<addr_from>\d+|[.$,;]|\/.*\/)(?:,(?<addr_to>\d+|[.$,;]|\/.*\/))?)?(?<cmnd>wq|[acdgijnpqrw=]|\z)(?<prmt>.*)?\n\z/ =~ input

        # コマンドを実行する
        p addr_from
        p addr_to
        p cmnd
        p prmt
    end

    def _print
        _read
    end
end

ED.new
