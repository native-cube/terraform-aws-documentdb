mock_provider "aws" {
  override_during = plan
  mock_resource "aws_docdb_cluster" {
    # Computed username represents the source cluster's inherited administrator.
    defaults = { master_username = "sourceadmin" }
  }
}

variables {
  name                           = "restored-docdb"
  final_snapshot_identifier      = "restored-docdb-final-v1"
  vpc_id                         = "vpc-0123456789abcdef0"
  subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  validate_network_configuration = false
  validate_engine_capabilities   = false
}

run "restore_credentials_remain_inherited_by_default" {
  command = plan
  variables {
    snapshot_identifier         = "source-snapshot"
    manage_master_user_password = false
    master_password_wo          = "MockReplacement123!"
    master_password_wo_version  = 2
  }
  assert {
    condition = (
      aws_docdb_cluster.main[0].master_username == "sourceadmin" &&
      aws_docdb_cluster.main[0].master_password_wo_version == null &&
      aws_docdb_cluster.main[0].manage_master_user_password == null
    )
    error_message = "Existing restore callers must continue inheriting credentials until they opt in."
  }
}

run "snapshot_adopts_managed_password_without_changing_username" {
  command = plan
  variables {
    snapshot_identifier              = "source-snapshot"
    manage_credentials_after_restore = true
  }
  assert {
    condition = (
      aws_docdb_cluster.main[0].manage_master_user_password == true &&
      aws_docdb_cluster.main[0].master_username == "sourceadmin" &&
      aws_docdb_cluster.main[0].master_password == null &&
      aws_docdb_cluster.main[0].master_password_wo_version == null
    )
    error_message = "Password adoption must leave the inherited username unchanged."
  }
}

run "snapshot_forwards_write_only_rotation_version" {
  command = plan
  variables {
    snapshot_identifier              = "source-snapshot"
    manage_credentials_after_restore = true
    manage_master_user_password      = false
    master_password_wo               = "MockReplacement123!"
    master_password_wo_version       = 2
  }
  assert {
    condition = (
      aws_docdb_cluster.main[0].master_password_wo_version == 2 &&
      aws_docdb_cluster.main[0].manage_master_user_password == null &&
      aws_docdb_cluster.main[0].master_password == null &&
      aws_docdb_cluster.main[0].master_username == "sourceadmin"
    )
    error_message = "The restored primary must receive the rotation version without changing its username or storing a legacy password."
  }
}

run "pitr_forwards_write_only_rotation_version" {
  command = plan
  variables {
    restore_to_point_in_time         = { source_cluster_identifier = "source", use_latest_restorable_time = true }
    manage_credentials_after_restore = true
    manage_master_user_password      = false
    master_password_wo               = "MockReplacement123!"
    master_password_wo_version       = 3
  }
  assert {
    condition = (
      aws_docdb_cluster.main[0].master_password_wo_version == 3 &&
      aws_docdb_cluster.main[0].master_username == "sourceadmin"
    )
    error_message = "PITR must also allow later password rotation while retaining the inherited username."
  }
}

run "restored_primary_requires_selected_password_mode" {
  command = plan
  variables {
    snapshot_identifier              = "source-snapshot"
    manage_credentials_after_restore = true
    manage_master_user_password      = false
  }
  expect_failures = [aws_docdb_cluster.main]
}

run "secondary_still_omits_credentials" {
  command = plan
  variables {
    is_primary_cluster               = false
    global_cluster_identifier        = "existing-global"
    manage_credentials_after_restore = true
    master_password_wo               = "MockReplacement123!"
    master_password_wo_version       = 2
  }
  assert {
    condition = (
      aws_docdb_cluster.main[0].manage_master_user_password == null &&
      aws_docdb_cluster.main[0].master_password_wo_version == null &&
      aws_docdb_cluster.main[0].master_username == "sourceadmin"
    )
    error_message = "The opt-in must never send credentials to a global secondary."
  }
}
