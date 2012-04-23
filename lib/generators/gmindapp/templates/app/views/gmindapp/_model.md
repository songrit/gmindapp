
### <%= model %>
<%- model_file= "#{Rails.root}/app/models/#{model}.rb" %>
<%= code(File.read(model_file)) %>

