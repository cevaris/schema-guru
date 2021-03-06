/*
 * Copyright (c) 2014 Snowplow Analytics Ltd. All rights reserved.
 *
 * This program is licensed to you under the Apache License Version 2.0,
 * and you may not use this file except in compliance with the Apache License Version 2.0.
 * You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the Apache License Version 2.0 is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.
 */
import sbt._

object Dependencies {

  val resolutionRepos = Seq(
    // For Snowplow libs
    "Snowplow Analytics Maven repo" at "http://maven.snplow.com/releases/",
    "Snowplow Analytics Maven snapshot repo" at "http://maven.snplow.com/snapshots/"
  )

  object V {
    // Java
    val yodaTime         = "2.1"
    val yodaConvert      = "1.2"
    val jacksonDatabind  = "2.2.3"
    val jsonValidator    = "2.2.3"
    val commonsValidator = "1.4.1"
    // Scala
    val argot            = "1.0.1"
    val scalaz7          = "7.0.6"
    val algebird         = "0.8.1"
    val json4s           = "3.2.11"
    val igluClient       = "0.1.1"
    // Scala (test only)
    val specs2           = "2.3.13"
    val scalazSpecs2     = "0.2"
    val scalaCheck       = "1.12.2"
    val commonsCodec     = "1.5"
  }

  object Libraries {
    // Java
    val yodaTime         = "joda-time"                  %  "joda-time"                 % V.yodaTime
    val yodaConvert      = "org.joda"                   %  "joda-convert"              % V.yodaConvert
    val jacksonDatabind  = "com.fasterxml.jackson.core" %  "jackson-databind"          % V.jacksonDatabind
    val jsonValidator    = "com.github.fge"             %  "json-schema-validator"     % V.jsonValidator
    val commonsValidator = "commons-validator"          %  "commons-validator"         % V.commonsValidator
    // Scala
    val argot            = "org.clapper"                %% "argot"                     % V.argot
    val scalaz7          = "org.scalaz"                 %% "scalaz-core"               % V.scalaz7
    val algebird         = "com.twitter"                %% "algebird-core"             % V.algebird
    val json4sJackson    = "org.json4s"                 %% "json4s-jackson"            % V.json4s
    val json4sScalaz     = "org.json4s"                 %% "json4s-scalaz"             % V.json4s    
    val igluClient       = "com.snowplowanalytics"      %  "iglu-scala-client"         % V.igluClient
    // Scala (test only)
    val specs2           = "org.specs2"                 %% "specs2"                    % V.specs2         % "test"
    val scalazSpecs2     = "org.typelevel"              %% "scalaz-specs2"             % V.scalazSpecs2   % "test"
    val scalaCheck       = "org.scalacheck"             %% "scalacheck"                % V.scalaCheck     % "test"
  }
}
