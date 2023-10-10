# frozen_string_literal: true

module LocaleText
  def self.for_scope(scope)
    scope = scope.split(".") if scope.is_a?(String)
    scope.map!(&:to_sym)

    result = Object.new

    result.define_singleton_method(:method_missing) do |mth, key = nil, **kwargs|
      if key
        I18n.t(key, scope: scope + [mth.to_sym], **kwargs)
      else
        I18n.t(mth, scope: scope, **kwargs)
      end
    end

    result
  end
end
