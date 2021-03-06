# encoding: utf-8
class ContentFilter
  class HasSpecimen < BooleanFilter
    def initialize
      super(
        sym:         :has_specimen,
        models:      [Observation],
        on_vals:     ["yes", "no"],
        checked_val: "yes",
        off_val:     nil
      )
    end

    def sql_conditions(query, model, val)
      ["observations.specimen IS #{val ? "TRUE" : "FALSE"}"]
    end
  end
end
