# MarkdownConversion は extend self のモジュールなので singleton_class に prepend する。
# lib/ はオートロード(リロード)対象のため、to_prepare でリロードのたびに再適用する。
Rails.application.config.to_prepare do
  ActionText::MarkdownConversion.singleton_class.prepend(CustomMarkdown)
end
