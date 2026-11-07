module SketchupMcp
  class TransactionManager
    def self.run(model, label)
      model.start_operation(label, true)
      begin
        result = yield
        model.commit_operation
        result
      rescue StandardError
        model.abort_operation
        raise
      end
    end
  end
end