require "json"

authors = Dir.foreach("authors").reject{%w[. ..].include? it}

analysis = 
  authors.map do |author|
    images = Dir.glob("authors/#{author}/*").select {
      File.basename(it).match?(/\A[1-9]\d*\.(png|jpe?g|gif|webp|svg)\z/i)
    }.sort_by { File.basename(it).to_i }
    value = 
      if images.any? { File.basename(it).to_i == 1 }
        # 連番画像だと思ってデータをつくる
        { type: "images", paths: images, pages: images.length }
      elsif File.exist? "authors/#{author}/1.pdf"
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
