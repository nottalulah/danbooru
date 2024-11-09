# frozen_string_literal: true

class Source::URL::Vgen < Source::URL
  RESERVED_USERNAMES = %w[my-requests creator settings commission c]

  def self.match?(url)
    url.domain == "vgen.co" || (url.host == "storage.googleapis.com" && url.path.start_with?("/vgen-production-storage/"))
  end

  attr_reader :username, :user_uuid, :portfolio_title, :portfolio_uuid, :service_name, :service_uuid, :character_name, :character_uuid, :concept_uuid, :filename

  def parse
    case [domain, *path_segments]

    # Character tab has separate pages
    # https://vgen.co/c/adelie/original
    in "vgen.co", "c", character_name, *rest
      @character_name = character_name

    # Portfolio tab works
    # https://vgen.co/ici/portfolio/showcase/akane-request/e7377737-ad3d-42c9-92d0-fc6529502a03
    in "vgen.co", username, "portfolio", "showcase", title, uuid
      @username = username unless username.in?(RESERVED_USERNAMES)
      @portfolio_title = title
      @portfolio_uuid = uuid

    # Commission tab works
    # https://vgen.co/ici/service/skeb-pwyw/f94d554a-1629-415f-b08a-2543cd67b516
    in "vgen.co", username, "service", service_name, uuid
      @username = username unless username.in?(RESERVED_USERNAMES)
      @service_name = service_name
      @service_uuid = uuid

    # Has to come after the other username-based routes
    # https://vgen.co/ici
    # https://vgen.co/a4492e52-aec3-4da4-bffe-836fd5db8e38
    in "vgen.co", username, *rest
      @username = username unless username.in?(RESERVED_USERNAMES)

    # Portfolio tab works
    # https://storage.googleapis.com/vgen-production-storage/uploads/a4492e52-aec3-4da4-bffe-836fd5db8e38/portfolio/301cd8f0-c25c-4d44-8b1e-faa4177feb3f.webp
    # Thumbnails' filenames are suffixed with `-thumbnail`
    in "googleapis.com", "vgen-production-storage", "uploads", user_uuid, "portfolio", filename
      @user_uuid = user_uuid
      @filename = filename.gsub("-thumbnail", "")

    # Character reference works
    # "https://storage.googleapis.com/vgen-production-storage/uploads/characters/34446b10-4157-46bf-a4cf-21139b9a3bc5/concepts/51d85aaf-a389-45c8-b595-8d9a72dd28d5/references/bdd472b6-d43c-4f9f-bf46-755388be8fff.webp
    in "googleapis.com", "vgen-production-storage", "uploads", "characters", character_uuid, "concepts", concept_uuid, "references", filename
      @character_uuid = character_uuid
      @concept_uuid = concept_uuid
      @filename = filename.gsub("-thumbnail", "")

    else
      nil
    end
  end

  def image_url?
    domain == "googleapis.com"
  end

  def full_image_url
    if user_uuid.present? && filename.present?
      "https://storage.googleapis.com/vgen-production-storage/uploads/#{user_uuid}/portfolio/#{filename}"
    elsif character_uuid.present? && concept_uuid.present? && filename.present?
      "https://storage.googleapis.com/vgen-production-storage/uploads/characters/#{character_uuid}/concept/#{concept_uuid}/references/#{filename}"
    end
  end

  def page_url
    if username.present? && portfolio_title.present? && portfolio_uuid.present?
      "https://vgen.co/#{username}/portfolio/showcase/#{portfolio_title}/#{portfolio_uuid}"
    elsif username.present? && service_name.present? && service_uuid.present?
      "https://vgen.co/#{username}/service/#{service_name}/#{service_uuid}"
    elsif character_name.present?
      "https://vgen.co/c/#{character_name}"
    end
  end

  def profile_url
    if username.present?
      "https://vgen.co/#{username}"
    elsif user_uuid.present?
      "https://vgen.co/#{user_uuid}"
    end
  end
end
