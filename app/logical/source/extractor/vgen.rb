# frozen_string_literal: true

# @see Source::URL::Vgen
class Source::Extractor
  class Vgen < Source::Extractor
    def image_urls
      if parsed_url.full_image_url.present?
        [parsed_url.full_image_url]
      elsif parsed_url.image_url?
        [parsed_url.to_s]
      else
        linked_item["galleryItems"].to_a.select { _1["type"] == "IMAGE" }.pluck("url")
      end
    end

    # def page_url
    # end

    def profile_urls
      [
        ("https://vgen.com/#{username}" if username.present?),
        ("https://vgen.com/#{user_uuid}" if user_uuid.present?),
      ].compact_blank.uniq
    end

    def artist_commentary_title
      linked_item.fetch("title", linked_item["serviceName"])
    end

    def artist_commentary_desc
      parsed_description
    end

    def tags
      linked_item["tags"].to_a.index_by { _1 }
    end

    def username
      props.dig("user", "username")
    end

    def user_uuid
      props.dig("user", "userID")
    end

    def display_name
      props.dig("user", "displayName")
    end

    # `description` consists of an array of hashes, where each hash contains a
    # `type` of element and one or more children, which can be additional elements
    # (for example, in lists), or text element.
    def parsed_description
      raw = linked_item["description"]&.parse_json
      raw = props.dig("character", "backstory")&.parse_json if raw.blank?
      return "" if raw.blank?

      raw.map do |item|
        case item["type"]

        when "heading-one"
          text = item["children"].sole["text"]
          "\nh1. #{text}\n"

        when "bulleted-list"
          item["children"].map do |child|
            text = child["children"].sole["text"]

            if child["children"].sole["underline"]
              "* [u] #{text} [/u]"
            else
              "* #{text}"
            end
          end.join("\n")

        when "paragraph"
          item["children"].map { _1["text"] }.join("\n")

        else
          # todo: remove error
          # raise "Unsupported type: #{item['type']}"
          puts "Warning: unsupported type: #{item['type']}"
          item
        end
      end.compact_blank.join("\n").strip
    end

    def http
      super.cookies("v-session": Danbooru.config.vgen_session_cookie)
    end

    def page
      http.cache(1.minute).parsed_get(page_url)
    end

    def page_json
      page&.at("#__NEXT_DATA__")&.text&.parse_json || {}
    end

    def props
      page_json.dig(:props, :pageProps).to_h.without(%w[startingTab serviceOrdering policies requestForms blocks initialUserID linkedServiceID linkedShowcaseID])
    end

    def linked_item
      props.fetch("linkedService", props.fetch("linkedShowcase", {}))
    end

    memoize :page, :page_json, :props
  end
end
