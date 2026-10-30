// 掲載順・執筆者・PDFのページ数はここで管理します。
#let contributors = (
  "white_green",
  "other_user",
)
#let contributors = contributors.map(name => {
  let metadata = json("authors/" + name + "/metadata.json")
  (
    name: name,
    displayname: metadata.at("name", default: name),
    title: metadata.at("title", default: name + " の原稿"),
    message: metadata.at("message", default: name + " のあとがき"),
  )
})
#let files = json("files.json")

#let trim-width = 210mm
#let trim-height = 297mm
#let bleed = 3mm
#let manuscript-width = trim-width + 2 * bleed
#let manuscript-height = trim-height + 2 * bleed
#set text(font: "Noto Sans CJK JP", lang: "ja", size: 11pt)
#set par(leading: 0.8em)

// --input size=bleed（既定）/ --input size=a4
#let output-size = sys.inputs.at("size", default: "bleed")
#assert(("bleed", "a4").contains(output-size), message: "size は bleed または a4 を指定してください")
#let output-for-author = sys.inputs.at("out-author", default: ":all:")
#let with-bleed = output-size == "bleed"
#let output-width = if with-bleed { manuscript-width } else { trim-width }
#let output-height = if with-bleed { manuscript-height } else { trim-height }
#let crop = if with-bleed { 0mm } else { bleed }
#let editorial-margin = 25mm + if with-bleed { bleed } else { 0mm }
#set document(title: "Test Book", author: contributors.map(c => c.name))
#set text(font: "Noto Sans CJK JP", lang: "ja", size: 11pt)
#set par(leading: 0.8em)
#let ink = black

// 表紙
#page(width: output-width, height: output-height, margin: editorial-margin, numbering: none)[
  #v(20mm)
  #text(size: 24pt)[Test Book]
  #v(8mm)
  合同冊子 / デモ版
  #v(16mm)
  #for c in contributors [
    #c.displayname #h(1em) #c.title #linebreak()
  ]
  #v(1fr)
  2026年10月4日
]

#let main_page(content) = page(
  width: output-width, height: output-height, margin: 0pt,
  numbering: (n, ..) => text(size: 9pt, fill: ink, numbering("1", n)),
  number-align: bottom + center,
  footer-descent: -(10mm + if with-bleed { bleed } else { 0mm }),
  content
)

// 入力は216×303mm。原寸配置し、A4版では左上を(-3mm, -3mm)へ移動。
// 出力サイズのクリップ領域で四辺3mmを削る。A4への縮小は行わない。
// 本文全体で1から連番を重ねる。補完白紙も数えるが番号は表示しない。
// 番号は仕上がり下端から10mm内側。塗り足し版も同じ仕上がり位置。
#counter(page).update(1)
#for c in contributors {
  let file_data = files.at(c.name)
  if ("pdf", "images").contains(file_data.type) {
    let pages = file_data.pages
    for n in range(1, pages + 1) {
      if output-for-author == c.name or output-for-author == ":all:" {
        main_page(place(top + left, block(width: output-width, height: output-height, clip: true)[
          #place(top + left, dx: -crop, dy: -crop,
            image(if file_data.type == "pdf" { file_data.path } else { file_data.paths.at(n - 1) },
              ..if file_data.type == "pdf" { (page: n) } else { (:) },
              width: manuscript-width, height: manuscript-height, fit: "contain",
              alt: c.name + "「" + c.title + "」" + str(n) + "ページ"))
        ]))
      } else {
        main_page(place(center + horizon, [#c.name #n ページ目]))
      }
    }
  }
  // 執筆者ごとに偶数ページへ切り上げる。補完ページは完全な白紙。
  if calc.rem(file_data.pages, 2) == 1 {
    page(width: output-width, height: output-height, margin: 0pt, numbering: none)[]
  }
}

// 奥付。
#page(width: output-width, height: output-height, margin: editorial-margin, numbering: none)[
  #v(1fr)
  #text(size: 18pt)[奥付]
  #v(8mm)
  #v(6mm)
  #table(
    columns: (28mm, 1fr), stroke: none, inset: (y: 5pt),
    [書名], [Test Book],
    [発行日], [2026年10月1日],
    [版], [デモ版・第1版],
    [執筆], contributors.map(c => c.displayname).join("、"),
    [編集・発行], [テスト編集部],
  )
  #v(8mm)
  本冊子の人物・本文・発行者はデモ用の架空のものです。
  #v(25mm)
]
