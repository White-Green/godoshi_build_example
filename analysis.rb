require "json"

authors = Dir.foreach("authors").reject{%w[. ..].include? it}

analysis = 
  authors.map do |author|
    value = 
      if File.exist? "authors/#{author}/1.pdf"
        # pdfだと思ってデータをつくる
        pages = `pdfinfo "authors/#{author}/1.pdf"`.split("\n").find{it.start_with? "Pages:"}.split[1].to_i
        {
          type: "pdf",
          path: "authors/#{author}/1.pdf",
          pages:,
        }
      else
        raise "ファイル形式の判別失敗"
      end
    [author, value]
  end.to_h

File.write("files.json", JSON.dump(analysis))
