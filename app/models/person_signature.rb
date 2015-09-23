class PersonSignature < ActiveRecord::Base
  attr_accessible :person_id, :organization_id
  belongs_to :person
  belongs_to :organization
  has_many :signatures

  scope :filter, -> (search_name, org_ids = nil){
    data = all.joins("LEFT JOIN people ON people.id = person_signatures.person_id")
      .joins("LEFT JOIN organizations ON organizations.id = person_signatures.organization_id")
    if data.present?
      if search_name.present?
        data = data.where("LOWER(CONCAT(people.first_name, ' ' , people.last_name)) LIKE ?", "%#{search_name.downcase}%")
      end
      if org_ids.present?
        data = data.where("organizations.id IN (?)", org_ids)
      end
    end
    data
  }

  scope :sort, -> (sort_query){
    return all unless sort_query.present?

    sort_query = sort_query[:s]
    if sort_query.present?
      all = joins("LEFT JOIN people ON people.id = person_signatures.person_id")
        .joins("LEFT JOIN organizations ON organizations.id = person_signatures.organization_id")
      if sort_query.include?('first_name')
        return all.order("people.first_name #{sort_query.include?('asc') ? "asc" : "desc"}")
      elsif sort_query.include?('last_name')
        return all.order("people.last_name #{sort_query.include?('asc') ? "asc" : "desc"}")
      elsif sort_query.include?('organization')
        return all.order("organizations.name #{sort_query.include?('asc') ? "asc" : "desc"}")
      elsif sort_query.include?('code_of_conduct_status')
        return all.joins("LEFT JOIN signatures ccs ON ccs.person_signature_id = person_signatures.id AND ccs.kind = 'code_of_conduct'")
          .order("ISNULL(ccs.status), ccs.status #{sort_query.include?('asc') ? "asc" : "desc"}")
      elsif sort_query.include?('statement_of_faith_status')
        return all.joins("LEFT JOIN signatures sfs ON sfs.person_signature_id = person_signatures.id AND sfs.kind = 'statement_of_faith'")
          .order("ISNULL(sfs.status), sfs.status #{sort_query.include?('asc') ? "asc" : "desc"}")
      elsif sort_query.include?('date_signed_at')
        return all.order("ISNULL(signatures.updated_at), MAX(signatures.updated_at) #{sort_query.include?('asc') ? "asc" : "desc"}")
      else
        return all.order("person_signatures.created_at asc")
      end
    else
      return order("person_signatures.created_at asc")
    end
  }

  scope :get_by_multiple_orgs, -> (org_ids){
    joins("INNER JOIN signatures ON signatures.person_signature_id = person_signatures.id")
    .where("person_signatures.organization_id IN (?)", org_ids)
    .group("signatures.person_signature_id")
  }

  def has_signed_signature?(kind)
    signature = self.signatures.find_by(kind: kind)
    return false unless signature.present?
    signature.status.present?
  end

  def signature_status(kind)
    signature = self.signatures.find_by(kind: kind)
    return nil unless signature.present?
    signature.status
  end

  def date_signed_at
    signature = self.signatures.last
    return "" unless signature.present?
    signature.updated_at
  end
end
