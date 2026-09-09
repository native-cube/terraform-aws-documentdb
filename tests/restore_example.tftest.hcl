mock_provider "aws" {}

# Isolate the example's input contract; root-module behavior is tested separately.
override_module {
  target = module.documentdb
  outputs = {
    cluster_endpoint        = "restored.example"
    cluster_reader_endpoint = "restored-reader.example"
    master_user_secret_arn  = null
  }
}

variables {
  name                          = "restore-example"
  region                        = "eu-west-1"
  engine_version                = "5.0.0"
  vpc_id                        = "vpc-0123456789abcdef0"
  subnet_ids                    = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  application_security_group_id = "sg-0123456789abcdef0"
  final_snapshot_identifier     = "restore-example-final-v1"
}

run "reject_missing_restore_source" {
  command = plan
  module {
    source = "./examples/restore"
  }
  expect_failures = [var.snapshot_identifier]
}

run "reject_both_restore_sources" {
  command = plan
  module {
    source = "./examples/restore"
  }
  variables {
    snapshot_identifier      = "source-snapshot"
    restore_to_point_in_time = { source_cluster_identifier = "source", use_latest_restorable_time = true }
  }
  expect_failures = [var.snapshot_identifier]
}

run "reject_empty_snapshot_identifier" {
  command = plan
  module {
    source = "./examples/restore"
  }
  variables {
    snapshot_identifier = ""
  }
  expect_failures = [var.snapshot_identifier]
}

run "reject_blank_snapshot_identifier" {
  command = plan
  module {
    source = "./examples/restore"
  }
  variables {
    snapshot_identifier = "   "
  }
  expect_failures = [var.snapshot_identifier]
}

run "accept_snapshot_restore" {
  command = plan
  module {
    source = "./examples/restore"
  }
  variables {
    snapshot_identifier = "source-snapshot"
  }
  assert {
    condition     = output.endpoint == "restored.example"
    error_message = "The example must accept a snapshot as its sole restore source."
  }
}

run "accept_point_in_time_restore" {
  command = plan
  module {
    source = "./examples/restore"
  }
  variables {
    restore_to_point_in_time = { source_cluster_identifier = "source", use_latest_restorable_time = true }
  }
  assert {
    condition     = output.endpoint == "restored.example"
    error_message = "The example must accept PITR as its sole restore source."
  }
}
