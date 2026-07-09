# CustomMarkdown の仕組み

`custom_markdown.rb` は、ActionText の HTML → Markdown 変換(`to_markdown`)に
アプリ独自の変換ルールを追加するためのファイルです。
`visit_<タグ名>` という名前のメソッドを定義すると、そのタグの変換ルールになります。

```ruby
# lib/custom_markdown.rb
module CustomMarkdown
  # <sample>Hello</sample> => "## SAMPLE -- Hello"
  def visit_sample(_node, child_values)
    "## SAMPLE -- #{join_children(child_values)}\n\n"
  end
end
```

```ruby
# config/initializers/custom_markdown.rb
Rails.application.config.to_prepare do
  ActionText::MarkdownConversion.singleton_class.prepend(CustomMarkdown)
end
```

## Rails 側で変換がどう動いているか

`ActionText::Content.new(html).to_markdown` を呼ぶと、次の順で処理されます。

1. [`ActionText::Content#to_markdown`](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/content.rb#L149)
   が入口です。ここから `Fragment#to_markdown` に処理を渡します。

2. [`ActionText::Fragment#to_markdown`](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/fragment.rb#L54)
   が `MarkdownConversion.node_to_markdown(source)` を呼びます。

3. [`MarkdownConversion.node_to_markdown`](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/markdown_conversion.rb#L25)
   は、HTML を木構造(Nokogiri のノード)として受け取り、
   [`BottomUpReducer`](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/bottom_up_reducer.rb)
   を使って「いちばん深い子」から順に Markdown へ変換していきます。
   あるタグを処理する時には、その中身(子要素)はすでに変換済みの文字列になっていて、
   `child_values` という配列で渡されます。

4. タグごとの変換は
   [`markdown_for_node`](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/markdown_conversion.rb#L92)
   が行います。ポイントは
   [L102-L108](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/markdown_conversion.rb#L102-L108)
   の部分です。

   ```ruby
   method_name = :"visit_#{node.name.tr("-", "_")}"
   if respond_to?(method_name, true)
     send(method_name, node, child_values)
   else
     join_children(child_values).strip
   end
   ```

   タグ名から `visit_h1` `visit_strong` のようなメソッド名を組み立てて、
   **そのメソッドがあれば呼ぶ**、という作りです。
   メソッドがないタグは、タグ自体はなかったことになり、中身だけが残ります
   (例: `visit_sample` がない状態では `<sample>TEST</sample>` は `TEST` になります)。

## このパッチがやっていること

上のディスパッチは「`visit_<タグ名>` というメソッドがあるか」だけを見ています。
そこで `MarkdownConversion` に `visit_sample` を追加して、
`<sample>` タグを変換できるようにしています。

- **prepend について** —
  `CustomMarkdown` のメソッドを `MarkdownConversion` に割り込ませる操作です。
  `MarkdownConversion` は [`extend self` されたモジュール](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/markdown_conversion.rb#L18-L19)
  なので、割り込ませる先は `singleton_class` になります。
  `visit_h1` のように Rails 側にすでにあるメソッドと同じ名前で定義すると、
  こちらが優先されて標準の変換を上書きできます。

- **to_prepare について** —
  ここに書いた処理は、サーバー起動時とコードのリロード時に毎回実行されます。
  development では `lib/` 配下のファイルは変更のたびにリロードされるので、
  `custom_markdown.rb` を編集して保存すれば、サーバー再起動なしで反映されます。
  (`config/initializers/` 側を変更したときだけ `docker compose restart rails` が必要です)

## visit_* メソッドの書き方

```ruby
def visit_<タグ名>(node, child_values)
```

- タグ名にハイフンがある場合は `_` に置き換えます(例: `<my-tag>` → `visit_my_tag`)
- `node` — 処理中のタグ(Nokogiri のノード)。属性は `node["href"]` のように取れます
- `child_values` — 変換済みの中身(文字列)の配列。`join_children(child_values)` でつなげます
- 戻り値 — このタグの Markdown 文字列。見出しや段落のようなブロック要素は
  末尾に `\n\n` を付けます(標準実装の
  [`visit_p`](https://github.com/rails/rails/blob/main/actiontext/lib/action_text/markdown_conversion.rb#L157-L159)
  も同じ書き方です)

## 動作確認

トップページ(`/`)の左側に `<sample>Hello</sample>` を入力して「変換」を押すか、
次のコマンドで確認できます。

```bash
docker compose exec rails bash -c \
  "cd /workspace/myapp && bin/rails runner 'puts ActionText::Content.new(\"<sample>Hello</sample>\").to_markdown'"
```

テストは `test/lib/custom_markdown_test.rb` にあります。
