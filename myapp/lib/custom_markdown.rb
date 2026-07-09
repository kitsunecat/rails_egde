# ActionText::MarkdownConversion に visit_* メソッドを追加・上書きするパッチ。
# ディスパッチは visit_#{タグ名} を動的に探すため、メソッドを定義するだけで
# 対応タグを増やせる。visit_* は (node, child_values) を受け取り、
# child_values には変換済みの子要素が入っている。
module CustomMarkdown
  # <sample>Hello</sample> => "## Hello"
  def visit_sample(_node, child_values)
    "## SAMPLE -- #{join_children(child_values)}\n\n"
  end
end
